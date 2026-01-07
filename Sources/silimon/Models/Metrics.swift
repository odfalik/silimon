import Foundation

/// Represents a snapshot of system metrics at a point in time
struct Metrics: Identifiable {
    let id = UUID()
    let timestamp: Date

    /// True once real data has been collected (vs initial empty state)
    var isCollected: Bool = false

    // GPU metrics
    var gpuUsage: Double = 0          // 0-100%
    var gpuFrequencyMHz: Double = 0
    var gpuPower: Double = 0          // Watts

    // CPU metrics
    var eCoreUsage: Double = 0        // 0-100%
    var pCoreUsage: Double = 0        // 0-100%
    var eCoreFrequencyMHz: Double = 0
    var pCoreFrequencyMHz: Double = 0
    var cpuPower: Double = 0          // Watts
    var eCoreCount: Int = 0           // Number of E-cores
    var pCoreCount: Int = 0           // Number of P-cores

    // Memory metrics
    var memoryUsedGB: Double = 0
    var memoryTotalGB: Double = 0
    var memoryPressure: MemoryPressure = .nominal
    var swapUsedGB: Double = 0

    // Power metrics
    var packagePower: Double = 0      // Total SoC power in Watts
    var anePower: Double = 0          // Neural Engine power in Watts

    // Battery metrics
    var batteryLevel: Double = 0      // 0-100%
    var batteryIsCharging: Bool = false
    var batteryTimeRemaining: Int? = nil  // Minutes remaining (nil if calculating or on AC)

    // Network metrics
    var networkBytesInPerSec: Double = 0
    var networkBytesOutPerSec: Double = 0

    // Thermal
    var thermalPressure: ThermalPressure = .nominal

    // Computed properties
    var memoryUsagePercent: Double {
        guard memoryTotalGB > 0 else { return 0 }
        return (memoryUsedGB / memoryTotalGB) * 100
    }

    var combinedCpuUsage: Double {
        // Core-count weighted average for accurate "% of total capacity"
        let eWeight = Double(eCoreCount)
        let pWeight = Double(pCoreCount)
        let total = eWeight + pWeight
        guard total > 0 else {
            // Fallback if core counts not available
            return (eCoreUsage + pCoreUsage) / 2
        }
        return (eCoreUsage * eWeight + pCoreUsage * pWeight) / total
    }

    static var empty: Metrics {
        Metrics(timestamp: Date())
    }
}

enum MemoryPressure: String, CaseIterable {
    case nominal
    case warn
    case critical

    var color: String {
        switch self {
        case .nominal: return "green"
        case .warn: return "yellow"
        case .critical: return "red"
        }
    }
}

enum ThermalPressure: String, CaseIterable {
    case nominal
    case fair
    case serious

    var color: String {
        switch self {
        case .nominal: return "green"
        case .fair: return "yellow"
        case .serious: return "red"
        }
    }
}

// MARK: - Chart Configuration

/// Shared chart configuration to ensure consistency between sparkline and popover charts
enum ChartConfig {
    /// Maximum Y-axis value for each metric type
    static func maxValue(for metric: MetricType) -> Double {
        switch metric {
        case .power: return 50.0      // 0-50 Watts
        case .cpu: return 100.0       // 0-100%
        case .gpu: return 100.0       // 0-100%
        case .memory: return 100.0    // 0-100%
        case .network: return 10.0    // 0-10 MB/s
        case .battery: return 100.0   // 0-100%
        }
    }

    /// Extract the chart value from a Metrics sample for a given metric type
    static func value(from sample: Metrics, for metric: MetricType) -> Double {
        switch metric {
        case .power: return sample.packagePower
        case .cpu: return sample.combinedCpuUsage
        case .gpu: return sample.gpuUsage
        case .memory: return sample.memoryUsagePercent
        case .network: return sample.networkBytesInPerSec / 1024 / 1024  // Convert to MB/s
        case .battery: return sample.batteryLevel
        }
    }

    /// Y-axis domain for SwiftUI Charts
    static func chartDomain(for metric: MetricType) -> ClosedRange<Double> {
        return 0...maxValue(for: metric)
    }
}
