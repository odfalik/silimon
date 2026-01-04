import Foundation
import IOReportLib

/// Service for collecting Apple Silicon power metrics via IOReport API
/// This replaces powermetrics and does not require sudo
class IOReportService {
    private var isInitialized = false
    private let samplingDurationMs: Int32
    private var consecutiveZeroSamples = 0
    private let maxZeroSamplesBeforeReinit = 3

    init(samplingDurationMs: Int32 = 100) {
        self.samplingDurationMs = samplingDurationMs
    }

    /// Initialize the IOReport subscription
    /// Must be called before collecting samples
    func initialize() -> Bool {
        guard !isInitialized else { return true }

        if initIOReport() {
            isInitialized = true
            consecutiveZeroSamples = 0
            return true
        }
        return false
    }

    /// Force reinitialization of IOReport subscription
    /// Call this if metrics become stale
    func reinitialize() -> Bool {
        cleanup()
        return initialize()
    }

    /// Check if IOReport is available on this system
    static var isAvailable: Bool {
        isIOReportAvailable()
    }

    /// Collect a single sample of metrics
    /// Returns nil if IOReport is not initialized or sampling fails
    /// Auto-reinitializes if subscription becomes stale (all zeros)
    func sample() -> SampleResult? {
        guard isInitialized else { return nil }

        let metrics = sampleMetrics(samplingDurationMs)
        guard metrics.valid else { return nil }

        // Detect stale subscription: all key metrics are zero
        let isAllZeros = metrics.packagePower == 0 &&
                         metrics.cpuPower == 0 &&
                         metrics.gpuPower == 0 &&
                         metrics.eCoreUsage == 0 &&
                         metrics.pCoreUsage == 0

        if isAllZeros {
            consecutiveZeroSamples += 1

            // After several consecutive zero samples, reinitialize
            if consecutiveZeroSamples >= maxZeroSamplesBeforeReinit {
                if reinitialize() {
                    // Retry sample after reinit
                    let retryMetrics = sampleMetrics(samplingDurationMs)
                    if retryMetrics.valid {
                        return SampleResult(
                            cpuPower: retryMetrics.cpuPower,
                            gpuPower: retryMetrics.gpuPower,
                            anePower: retryMetrics.anePower,
                            packagePower: retryMetrics.packagePower,
                            eCoreUsage: retryMetrics.eCoreUsage,
                            pCoreUsage: retryMetrics.pCoreUsage,
                            eCoreFreqMHz: Double(retryMetrics.eCoreFreqMHz),
                            pCoreFreqMHz: Double(retryMetrics.pCoreFreqMHz),
                            gpuUsage: retryMetrics.gpuUsage,
                            gpuFreqMHz: Double(retryMetrics.gpuFreqMHz),
                            thermalPressure: ThermalPressure(rawValue: retryMetrics.thermalState)
                        )
                    }
                }
            }
        } else {
            consecutiveZeroSamples = 0
        }

        return SampleResult(
            cpuPower: metrics.cpuPower,
            gpuPower: metrics.gpuPower,
            anePower: metrics.anePower,
            packagePower: metrics.packagePower,
            eCoreUsage: metrics.eCoreUsage,
            pCoreUsage: metrics.pCoreUsage,
            eCoreFreqMHz: Double(metrics.eCoreFreqMHz),
            pCoreFreqMHz: Double(metrics.pCoreFreqMHz),
            gpuUsage: metrics.gpuUsage,
            gpuFreqMHz: Double(metrics.gpuFreqMHz),
            thermalPressure: ThermalPressure(rawValue: metrics.thermalState)
        )
    }

    /// Clean up resources
    func cleanup() {
        if isInitialized {
            cleanupIOReport()
            isInitialized = false
        }
    }

    deinit {
        cleanup()
    }

    /// Sample result with all metrics
    struct SampleResult {
        let cpuPower: Double
        let gpuPower: Double
        let anePower: Double
        let packagePower: Double

        let eCoreUsage: Double
        let pCoreUsage: Double
        let eCoreFreqMHz: Double
        let pCoreFreqMHz: Double

        let gpuUsage: Double
        let gpuFreqMHz: Double

        let thermalPressure: ThermalPressure
    }
}

/// Extension to map thermal state int to ThermalPressure enum
extension ThermalPressure {
    init(rawValue: Int32) {
        // NSProcessInfoThermalState values:
        // 0 = nominal, 1 = fair, 2 = serious, 3 = critical
        switch rawValue {
        case 2, 3:
            self = .serious
        case 1:
            self = .fair
        default:
            self = .nominal
        }
    }
}
