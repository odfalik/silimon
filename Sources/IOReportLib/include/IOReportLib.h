//
//  IOReportLib.h
//  IOReport API wrapper for Apple Silicon power metrics
//
//  Based on the IOReport private framework used by powermetrics
//  Provides access to CPU, GPU, ANE power consumption without sudo
//

#ifndef IOReportLib_h
#define IOReportLib_h

#include <stdint.h>
#include <stdbool.h>

/// Power and performance metrics from Apple Silicon SoC
typedef struct {
    // Power consumption in watts
    double cpuPower;
    double gpuPower;
    double anePower;
    double dramPower;
    double packagePower;  // Total SoC power

    // CPU cluster metrics
    double eCoreUsage;      // 0-100%
    double pCoreUsage;      // 0-100%
    int eCoreFreqMHz;
    int pCoreFreqMHz;

    // GPU metrics
    double gpuUsage;        // 0-100%
    int gpuFreqMHz;

    // Thermal (from ProcessInfo, not IOReport)
    int thermalState;       // 0=nominal, 1=fair, 2=serious, 3=critical

    // Status
    bool valid;
    char errorMessage[256];
} SocMetrics;

/// Initialize the IOReport subscription
/// Must be called before sampleMetrics()
/// Returns true on success, false on failure
bool initIOReport(void);

/// Sample power metrics over the specified duration
/// @param durationMs Sampling duration in milliseconds (typically 100-1000ms)
/// @return SocMetrics structure with power/frequency/usage data
SocMetrics sampleMetrics(int durationMs);

/// Clean up IOReport resources
/// Should be called when done collecting metrics
void cleanupIOReport(void);

/// Check if IOReport is available on this system
bool isIOReportAvailable(void);

/// Debug: print all available channels to stderr
void debugPrintChannels(void);

#endif /* IOReportLib_h */
