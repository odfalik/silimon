import Foundation

/// Represents a snapshot of system metrics at a point in time
struct Metrics: Identifiable {
    let id = UUID()
    let timestamp: Date

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

    // Memory metrics
    var memoryUsedGB: Double = 0
    var memoryTotalGB: Double = 0
    var memoryPressure: MemoryPressure = .nominal
    var swapUsedGB: Double = 0

    // Power metrics
    var packagePower: Double = 0      // Total SoC power in Watts
    var anePower: Double = 0          // Neural Engine power in Watts

    // Thermal
    var thermalPressure: ThermalPressure = .nominal

    // Computed properties
    var memoryUsagePercent: Double {
        guard memoryTotalGB > 0 else { return 0 }
        return (memoryUsedGB / memoryTotalGB) * 100
    }

    var combinedCpuUsage: Double {
        // Weighted average - P-cores typically have more impact
        return (eCoreUsage + pCoreUsage * 2) / 3
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
