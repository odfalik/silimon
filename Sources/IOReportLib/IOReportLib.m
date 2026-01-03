//
//  IOReportLib.m
//  IOReport API implementation for Apple Silicon power metrics
//
//  Based on mactop's IOReport implementation (MIT License)
//  https://github.com/metaspartan/mactop
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import "include/IOReportLib.h"

// IOReport private framework declarations
// These are not publicly documented but are stable across macOS versions
typedef CFDictionaryRef IOReportSubscriptionRef;

extern CFDictionaryRef IOReportCopyChannelsInGroup(CFStringRef group, CFStringRef subgroup,
                                                    uint64_t a, uint64_t b, uint64_t c);
extern void IOReportMergeChannels(CFMutableDictionaryRef a, CFDictionaryRef b, CFTypeRef null);
extern IOReportSubscriptionRef IOReportCreateSubscription(void *a, CFMutableDictionaryRef channels,
                                                           CFMutableDictionaryRef *subscribed,
                                                           uint64_t channel_id, CFTypeRef null);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef subscription,
                                              CFMutableDictionaryRef subscribed, CFTypeRef null);
extern CFDictionaryRef IOReportCreateSamplesDelta(CFDictionaryRef prev, CFDictionaryRef current,
                                                   CFTypeRef null);
extern CFStringRef IOReportChannelGetGroup(CFDictionaryRef channel);
extern CFStringRef IOReportChannelGetSubGroup(CFDictionaryRef channel);
extern CFStringRef IOReportChannelGetChannelName(CFDictionaryRef channel);
extern int64_t IOReportSimpleGetIntegerValue(CFDictionaryRef channel, int64_t defaultValue);
extern CFStringRef IOReportChannelGetUnitLabel(CFDictionaryRef channel);
extern int IOReportStateGetCount(CFDictionaryRef channel);
extern int64_t IOReportStateGetResidency(CFDictionaryRef channel, int index);
extern CFStringRef IOReportStateGetNameForIndex(CFDictionaryRef channel, int index);
extern uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef channel, int index);

// Global subscription state
static IOReportSubscriptionRef subscription = NULL;
static CFMutableDictionaryRef subscribedChannels = NULL;
static bool initialized = false;

// Frequency tables (loaded once at init)
static int *eClusterFreqs = NULL;
static int eClusterFreqCount = 0;
static int *pClusterFreqs = NULL;
static int pClusterFreqCount = 0;
static int *gpuFreqs = NULL;
static int gpuFreqCount = 0;

#pragma mark - Frequency Table Loading

static void loadFrequencyTables(void) {
    // Load CPU frequency tables from IORegistry
    io_registry_entry_t entry = IORegistryEntryFromPath(kIOMainPortDefault,
        "IOService:/AppleARMPE/arm-io/pmgr");

    if (entry != MACH_PORT_NULL) {
        // E-cluster frequencies
        CFDataRef eClusterData = IORegistryEntryCreateCFProperty(entry,
            CFSTR("voltage-states1-sram"), kCFAllocatorDefault, 0);
        if (eClusterData) {
            size_t len = CFDataGetLength(eClusterData);
            const uint8_t *bytes = CFDataGetBytePtr(eClusterData);
            eClusterFreqCount = (int)(len / 8);
            eClusterFreqs = malloc(eClusterFreqCount * sizeof(int));
            for (int i = 0; i < eClusterFreqCount; i++) {
                uint32_t freq;
                memcpy(&freq, bytes + i * 8, 4);
                eClusterFreqs[i] = freq / 1000000;  // Hz to MHz
            }
            CFRelease(eClusterData);
        }

        // P-cluster frequencies
        CFDataRef pClusterData = IORegistryEntryCreateCFProperty(entry,
            CFSTR("voltage-states5-sram"), kCFAllocatorDefault, 0);
        if (pClusterData) {
            size_t len = CFDataGetLength(pClusterData);
            const uint8_t *bytes = CFDataGetBytePtr(pClusterData);
            pClusterFreqCount = (int)(len / 8);
            pClusterFreqs = malloc(pClusterFreqCount * sizeof(int));
            for (int i = 0; i < pClusterFreqCount; i++) {
                uint32_t freq;
                memcpy(&freq, bytes + i * 8, 4);
                pClusterFreqs[i] = freq / 1000000;
            }
            CFRelease(pClusterData);
        }

        // GPU frequencies - try multiple property names for different chip variants
        CFDataRef gpuData = IORegistryEntryCreateCFProperty(entry,
            CFSTR("voltage-states9-sram"), kCFAllocatorDefault, 0);
        if (!gpuData) {
            gpuData = IORegistryEntryCreateCFProperty(entry,
                CFSTR("voltage-states9"), kCFAllocatorDefault, 0);
        }
        if (!gpuData) {
            gpuData = IORegistryEntryCreateCFProperty(entry,
                CFSTR("voltage-states8-sram"), kCFAllocatorDefault, 0);
        }
        if (gpuData) {
            size_t len = CFDataGetLength(gpuData);
            const uint8_t *bytes = CFDataGetBytePtr(gpuData);
            gpuFreqCount = (int)(len / 8);
            gpuFreqs = malloc(gpuFreqCount * sizeof(int));
            for (int i = 0; i < gpuFreqCount; i++) {
                uint32_t freq;
                memcpy(&freq, bytes + i * 8, 4);
                gpuFreqs[i] = freq / 1000000;
            }
            CFRelease(gpuData);
        }

        IOObjectRelease(entry);
    }
}

#pragma mark - Energy Conversion

static double energyToWatts(int64_t energy, double durationNs, CFStringRef unit) {
    if (durationNs <= 0) return 0;

    double durationS = durationNs / 1e9;
    double scale = 1.0;

    if (unit) {
        if (CFStringCompare(unit, CFSTR("mJ"), 0) == kCFCompareEqualTo) {
            scale = 1e-3;
        } else if (CFStringCompare(unit, CFSTR("uJ"), 0) == kCFCompareEqualTo) {
            scale = 1e-6;
        } else if (CFStringCompare(unit, CFSTR("nJ"), 0) == kCFCompareEqualTo) {
            scale = 1e-9;
        }
    }

    return (energy * scale) / durationS;
}

#pragma mark - Weighted Frequency Calculation

static int calculateWeightedFreq(CFDictionaryRef channel, int *freqTable, int freqCount) {
    if (!freqTable || freqCount == 0) return 0;

    int stateCount = IOReportStateGetCount(channel);
    if (stateCount <= 0) return 0;

    int64_t activeResidency = 0;
    int64_t weightedSum = 0;

    for (int i = 0; i < stateCount && i < freqCount; i++) {
        int64_t residency = IOReportStateGetResidency(channel, i);
        if (residency <= 0) continue;

        // Skip idle/off states - only count active P-states for frequency
        CFStringRef stateName = IOReportStateGetNameForIndex(channel, i);
        bool isIdle = (i == 0);  // State 0 is typically idle
        if (stateName) {
            if (CFStringFind(stateName, CFSTR("IDLE"), kCFCompareCaseInsensitive).location != kCFNotFound ||
                CFStringFind(stateName, CFSTR("OFF"), kCFCompareCaseInsensitive).location != kCFNotFound ||
                CFStringFind(stateName, CFSTR("DOWN"), kCFCompareCaseInsensitive).location != kCFNotFound) {
                isIdle = true;
            }
        }

        if (!isIdle && freqTable[i] > 0) {
            activeResidency += residency;
            weightedSum += residency * freqTable[i];
        }
    }

    if (activeResidency > 0) {
        return (int)(weightedSum / activeResidency);
    }
    return 0;
}

static double calculateActiveRatio(CFDictionaryRef channel) {
    int stateCount = IOReportStateGetCount(channel);
    if (stateCount <= 0) return 0;

    int64_t idleResidency = 0;
    int64_t totalResidency = 0;

    for (int i = 0; i < stateCount; i++) {
        int64_t residency = IOReportStateGetResidency(channel, i);
        totalResidency += residency;

        CFStringRef stateName = IOReportStateGetNameForIndex(channel, i);
        if (stateName) {
            // State 0 or states containing "IDLE" or "OFF" are idle states
            if (i == 0 || CFStringFind(stateName, CFSTR("IDLE"), kCFCompareCaseInsensitive).location != kCFNotFound ||
                CFStringFind(stateName, CFSTR("OFF"), kCFCompareCaseInsensitive).location != kCFNotFound) {
                idleResidency += residency;
            }
        } else if (i == 0) {
            idleResidency += residency;
        }
    }

    if (totalResidency > 0) {
        return (1.0 - (double)idleResidency / totalResidency) * 100.0;
    }
    return 0;
}

#pragma mark - Public API

bool isIOReportAvailable(void) {
    // Check if we can load the IOReport framework
    CFDictionaryRef testChannels = IOReportCopyChannelsInGroup(CFSTR("Energy Model"), NULL, 0, 0, 0);
    if (testChannels) {
        CFRelease(testChannels);
        return true;
    }
    return false;
}

bool initIOReport(void) {
    if (initialized) return true;

    // Load frequency tables
    loadFrequencyTables();

    // Get channels for energy, GPU stats, and CPU stats
    CFMutableDictionaryRef channels = NULL;

    CFDictionaryRef energyChannels = IOReportCopyChannelsInGroup(CFSTR("Energy Model"), NULL, 0, 0, 0);
    if (energyChannels) {
        channels = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, energyChannels);
        CFRelease(energyChannels);
    }

    CFDictionaryRef gpuChannels = IOReportCopyChannelsInGroup(CFSTR("GPU Stats"), NULL, 0, 0, 0);
    if (gpuChannels) {
        if (channels) {
            IOReportMergeChannels(channels, gpuChannels, NULL);
        } else {
            channels = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, gpuChannels);
        }
        CFRelease(gpuChannels);
    }

    CFDictionaryRef cpuChannels = IOReportCopyChannelsInGroup(CFSTR("CPU Stats"), NULL, 0, 0, 0);
    if (cpuChannels) {
        if (channels) {
            IOReportMergeChannels(channels, cpuChannels, NULL);
        } else {
            channels = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, cpuChannels);
        }
        CFRelease(cpuChannels);
    }

    if (!channels) {
        return false;
    }

    // Create subscription
    subscription = IOReportCreateSubscription(NULL, channels, &subscribedChannels, 0, NULL);
    CFRelease(channels);

    if (!subscription) {
        return false;
    }

    initialized = true;
    return true;
}

SocMetrics sampleMetrics(int durationMs) {
    SocMetrics metrics = {0};
    metrics.valid = false;

    if (!initialized) {
        snprintf(metrics.errorMessage, sizeof(metrics.errorMessage), "IOReport not initialized");
        return metrics;
    }

    // Take first sample
    CFDictionaryRef sample1 = IOReportCreateSamples(subscription, subscribedChannels, NULL);
    if (!sample1) {
        snprintf(metrics.errorMessage, sizeof(metrics.errorMessage), "Failed to create first sample");
        return metrics;
    }

    // Wait for duration
    uint64_t startTime = clock_gettime_nsec_np(CLOCK_MONOTONIC);
    usleep(durationMs * 1000);
    uint64_t endTime = clock_gettime_nsec_np(CLOCK_MONOTONIC);
    double durationNs = (double)(endTime - startTime);

    // Take second sample
    CFDictionaryRef sample2 = IOReportCreateSamples(subscription, subscribedChannels, NULL);
    if (!sample2) {
        CFRelease(sample1);
        snprintf(metrics.errorMessage, sizeof(metrics.errorMessage), "Failed to create second sample");
        return metrics;
    }

    // Calculate delta
    CFDictionaryRef delta = IOReportCreateSamplesDelta(sample1, sample2, NULL);
    CFRelease(sample1);
    CFRelease(sample2);

    if (!delta) {
        snprintf(metrics.errorMessage, sizeof(metrics.errorMessage), "Failed to create delta");
        return metrics;
    }

    // Parse delta for metrics
    CFArrayRef channelArray = CFDictionaryGetValue(delta, CFSTR("IOReportChannels"));
    if (!channelArray) {
        CFRelease(delta);
        snprintf(metrics.errorMessage, sizeof(metrics.errorMessage), "No channels in delta");
        return metrics;
    }

    // Accumulators for averaging
    double eClusterUsageSum = 0;
    int eClusterCount = 0;
    double pClusterUsageSum = 0;
    int pClusterCount = 0;
    int eClusterFreqSum = 0;
    int pClusterFreqSum = 0;

    CFIndex count = CFArrayGetCount(channelArray);
    for (CFIndex i = 0; i < count; i++) {
        CFDictionaryRef channel = CFArrayGetValueAtIndex(channelArray, i);
        if (!channel) continue;

        CFStringRef group = IOReportChannelGetGroup(channel);
        CFStringRef subgroup = IOReportChannelGetSubGroup(channel);
        CFStringRef name = IOReportChannelGetChannelName(channel);

        if (!group || !name) continue;

        // Energy Model group - power consumption
        if (CFStringCompare(group, CFSTR("Energy Model"), 0) == kCFCompareEqualTo) {
            int64_t energy = IOReportSimpleGetIntegerValue(channel, 0);
            CFStringRef unit = IOReportChannelGetUnitLabel(channel);
            double watts = energyToWatts(energy, durationNs, unit);

            // GPU Power - match "GPU Energy" or "GPU0 Energy" etc
            if (CFStringFind(name, CFSTR("GPU"), 0).location != kCFNotFound &&
                CFStringFind(name, CFSTR("Energy"), 0).location != kCFNotFound) {
                metrics.gpuPower += watts;
            }
            // CPU Power - match "CPU Energy" but not GPU
            else if (CFStringFind(name, CFSTR("CPU"), 0).location != kCFNotFound &&
                     CFStringFind(name, CFSTR("Energy"), 0).location != kCFNotFound) {
                metrics.cpuPower += watts;
            }
            // ANE Power
            else if (CFStringFind(name, CFSTR("ANE"), 0).location != kCFNotFound) {
                metrics.anePower += watts;
            }
            // DRAM Power
            else if (CFStringFind(name, CFSTR("DRAM"), 0).location != kCFNotFound) {
                metrics.dramPower += watts;
            }
        }
        // CPU Stats group - cluster frequencies and usage
        else if (CFStringCompare(group, CFSTR("CPU Stats"), 0) == kCFCompareEqualTo) {
            if (subgroup && CFStringFind(subgroup, CFSTR("CPU Complex Performance States"), 0).location != kCFNotFound) {
                // E-cluster
                if (CFStringFind(name, CFSTR("ECPU"), 0).location != kCFNotFound ||
                    CFStringFind(name, CFSTR("E-Cluster"), 0).location != kCFNotFound) {
                    double usage = calculateActiveRatio(channel);
                    eClusterUsageSum += usage;
                    eClusterCount++;
                    eClusterFreqSum += calculateWeightedFreq(channel, eClusterFreqs, eClusterFreqCount);
                }
                // P-cluster
                else if (CFStringFind(name, CFSTR("PCPU"), 0).location != kCFNotFound ||
                         CFStringFind(name, CFSTR("P-Cluster"), 0).location != kCFNotFound ||
                         CFStringFind(name, CFSTR("P0-Cluster"), 0).location != kCFNotFound ||
                         CFStringFind(name, CFSTR("P1-Cluster"), 0).location != kCFNotFound) {
                    double usage = calculateActiveRatio(channel);
                    pClusterUsageSum += usage;
                    pClusterCount++;
                    pClusterFreqSum += calculateWeightedFreq(channel, pClusterFreqs, pClusterFreqCount);
                }
            }
        }
        // GPU Stats group - look for GPUPH channel in GPU Performance States subgroup
        else if (CFStringCompare(group, CFSTR("GPU Stats"), 0) == kCFCompareEqualTo) {
            if (subgroup && CFStringFind(subgroup, CFSTR("GPU Performance States"), 0).location != kCFNotFound) {
                if (CFStringFind(name, CFSTR("GPUPH"), 0).location != kCFNotFound) {
                    metrics.gpuUsage = calculateActiveRatio(channel);
                    metrics.gpuFreqMHz = calculateWeightedFreq(channel, gpuFreqs, gpuFreqCount);
                }
            }
        }
    }

    CFRelease(delta);

    // Calculate averages
    if (eClusterCount > 0) {
        metrics.eCoreUsage = eClusterUsageSum / eClusterCount;
        metrics.eCoreFreqMHz = eClusterFreqSum / eClusterCount;
    }
    if (pClusterCount > 0) {
        metrics.pCoreUsage = pClusterUsageSum / pClusterCount;
        metrics.pCoreFreqMHz = pClusterFreqSum / pClusterCount;
    }

    // Calculate total package power
    metrics.packagePower = metrics.cpuPower + metrics.gpuPower + metrics.anePower + metrics.dramPower;

    // Get thermal state from ProcessInfo (not IOReport)
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    metrics.thermalState = (int)thermalState;

    metrics.valid = true;
    return metrics;
}

void cleanupIOReport(void) {
    if (subscription) {
        CFRelease(subscription);
        subscription = NULL;
    }
    if (subscribedChannels) {
        CFRelease(subscribedChannels);
        subscribedChannels = NULL;
    }
    if (eClusterFreqs) {
        free(eClusterFreqs);
        eClusterFreqs = NULL;
    }
    if (pClusterFreqs) {
        free(pClusterFreqs);
        pClusterFreqs = NULL;
    }
    if (gpuFreqs) {
        free(gpuFreqs);
        gpuFreqs = NULL;
    }
    eClusterFreqCount = 0;
    pClusterFreqCount = 0;
    gpuFreqCount = 0;
    initialized = false;
}
