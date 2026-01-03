import Foundation

/// Parses powermetrics plist output to extract Apple Silicon metrics
struct PowerMetricsParser {
    struct Result {
        var gpuUsage: Double = 0
        var gpuFrequencyMHz: Double = 0
        var gpuPower: Double = 0

        var eCoreUsage: Double = 0
        var pCoreUsage: Double = 0
        var eCoreFrequencyMHz: Double = 0
        var pCoreFrequencyMHz: Double = 0
        var cpuPower: Double = 0

        var packagePower: Double = 0
        var anePower: Double = 0

        var thermalPressure: ThermalPressure = .nominal
    }

    func parse(from url: URL) -> Result? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        var result = Result()

        // Parse GPU metrics
        if let gpu = plist["gpu"] as? [String: Any] {
            if let idleRatio = gpu["gpu_idle_ratio"] as? Double {
                result.gpuUsage = (1 - idleRatio) * 100
            }
            if let freqHz = gpu["gpu_freq_hz"] as? Double {
                result.gpuFrequencyMHz = freqHz / 1_000_000
            }
            if let powerMw = gpu["gpu_power"] as? Double {
                result.gpuPower = powerMw / 1000
            }
        }

        // Parse CPU cluster metrics
        if let processor = plist["processor"] as? [String: Any],
           let clusters = processor["clusters"] as? [[String: Any]] {

            var eClusterUsage: [Double] = []
            var pClusterUsage: [Double] = []
            var eClusterFreq: [Double] = []
            var pClusterFreq: [Double] = []

            for cluster in clusters {
                guard let name = cluster["name"] as? String else { continue }
                let isECluster = name.lowercased().contains("e")

                if let idleRatio = cluster["idle_ratio"] as? Double {
                    let usage = (1 - idleRatio) * 100
                    if isECluster {
                        eClusterUsage.append(usage)
                    } else {
                        pClusterUsage.append(usage)
                    }
                }

                if let freqHz = cluster["freq_hz"] as? Double {
                    let freqMHz = freqHz / 1_000_000
                    if isECluster {
                        eClusterFreq.append(freqMHz)
                    } else {
                        pClusterFreq.append(freqMHz)
                    }
                }
            }

            // Average across clusters
            if !eClusterUsage.isEmpty {
                result.eCoreUsage = eClusterUsage.reduce(0, +) / Double(eClusterUsage.count)
            }
            if !pClusterUsage.isEmpty {
                result.pCoreUsage = pClusterUsage.reduce(0, +) / Double(pClusterUsage.count)
            }
            if !eClusterFreq.isEmpty {
                result.eCoreFrequencyMHz = eClusterFreq.reduce(0, +) / Double(eClusterFreq.count)
            }
            if !pClusterFreq.isEmpty {
                result.pCoreFrequencyMHz = pClusterFreq.reduce(0, +) / Double(pClusterFreq.count)
            }
        }

        // Parse power metrics
        if let processor = plist["processor"] as? [String: Any] {
            if let cpuPowerMw = processor["combined_power"] as? Double {
                result.cpuPower = cpuPowerMw / 1000
            } else if let cpuPowerMw = processor["cpu_power"] as? Double {
                result.cpuPower = cpuPowerMw / 1000
            }

            if let packagePowerMw = processor["package_power"] as? Double {
                result.packagePower = packagePowerMw / 1000
            }

            if let anePowerMw = processor["ane_power"] as? Double {
                result.anePower = anePowerMw / 1000
            }
        }

        // Parse thermal metrics
        if let thermal = plist["thermal_pressure"] as? String {
            switch thermal.lowercased() {
            case "serious":
                result.thermalPressure = .serious
            case "fair":
                result.thermalPressure = .fair
            default:
                result.thermalPressure = .nominal
            }
        }

        return result
    }
}
