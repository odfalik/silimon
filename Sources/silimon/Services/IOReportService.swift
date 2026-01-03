import Foundation
import IOReportLib

/// Service for collecting Apple Silicon power metrics via IOReport API
/// This replaces powermetrics and does not require sudo
class IOReportService {
    private var isInitialized = false
    private let samplingDurationMs: Int32

    init(samplingDurationMs: Int32 = 100) {
        self.samplingDurationMs = samplingDurationMs
    }

    /// Initialize the IOReport subscription
    /// Must be called before collecting samples
    func initialize() -> Bool {
        guard !isInitialized else { return true }

        if initIOReport() {
            isInitialized = true
            return true
        }
        return false
    }

    /// Check if IOReport is available on this system
    static var isAvailable: Bool {
        isIOReportAvailable()
    }

    /// Collect a single sample of metrics
    /// Returns nil if IOReport is not initialized or sampling fails
    func sample() -> SampleResult? {
        guard isInitialized else { return nil }

        let metrics = sampleMetrics(samplingDurationMs)
        guard metrics.valid else { return nil }

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
