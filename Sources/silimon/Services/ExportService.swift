import Foundation
import AppKit

/// Service for exporting metrics history to CSV or JSON
class ExportService {
    static let shared = ExportService()

    private init() {}

    /// Export metrics history to CSV format
    func exportToCSV(_ samples: [Metrics]) -> String {
        var csv = "timestamp,package_power_w,cpu_power_w,gpu_power_w,ane_power_w,"
        csv += "e_core_usage_pct,p_core_usage_pct,e_core_freq_mhz,p_core_freq_mhz,"
        csv += "gpu_usage_pct,gpu_freq_mhz,"
        csv += "memory_used_gb,memory_total_gb,memory_pressure,swap_gb,"
        csv += "battery_pct,battery_charging,"
        csv += "network_in_bps,network_out_bps,"
        csv += "thermal_pressure\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for sample in samples {
            let row = [
                dateFormatter.string(from: sample.timestamp),
                String(format: "%.2f", sample.packagePower),
                String(format: "%.2f", sample.cpuPower),
                String(format: "%.2f", sample.gpuPower),
                String(format: "%.2f", sample.anePower),
                String(format: "%.1f", sample.eCoreUsage),
                String(format: "%.1f", sample.pCoreUsage),
                String(format: "%.0f", sample.eCoreFrequencyMHz),
                String(format: "%.0f", sample.pCoreFrequencyMHz),
                String(format: "%.1f", sample.gpuUsage),
                String(format: "%.0f", sample.gpuFrequencyMHz),
                String(format: "%.2f", sample.memoryUsedGB),
                String(format: "%.2f", sample.memoryTotalGB),
                sample.memoryPressure.rawValue,
                String(format: "%.2f", sample.swapUsedGB),
                String(format: "%.1f", sample.batteryLevel),
                sample.batteryIsCharging ? "true" : "false",
                String(format: "%.0f", sample.networkBytesInPerSec),
                String(format: "%.0f", sample.networkBytesOutPerSec),
                sample.thermalPressure.rawValue
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Export metrics history to JSON format
    func exportToJSON(_ samples: [Metrics]) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = samples.map { sample -> [String: Any] in
            [
                "timestamp": ISO8601DateFormatter().string(from: sample.timestamp),
                "power": [
                    "package_w": sample.packagePower,
                    "cpu_w": sample.cpuPower,
                    "gpu_w": sample.gpuPower,
                    "ane_w": sample.anePower
                ],
                "cpu": [
                    "e_core_usage_pct": sample.eCoreUsage,
                    "p_core_usage_pct": sample.pCoreUsage,
                    "e_core_freq_mhz": sample.eCoreFrequencyMHz,
                    "p_core_freq_mhz": sample.pCoreFrequencyMHz,
                    "combined_usage_pct": sample.combinedCpuUsage
                ],
                "gpu": [
                    "usage_pct": sample.gpuUsage,
                    "freq_mhz": sample.gpuFrequencyMHz
                ],
                "memory": [
                    "used_gb": sample.memoryUsedGB,
                    "total_gb": sample.memoryTotalGB,
                    "usage_pct": sample.memoryUsagePercent,
                    "pressure": sample.memoryPressure.rawValue,
                    "swap_gb": sample.swapUsedGB
                ],
                "battery": [
                    "level_pct": sample.batteryLevel,
                    "charging": sample.batteryIsCharging,
                    "time_remaining_min": sample.batteryTimeRemaining as Any
                ],
                "network": [
                    "bytes_in_per_sec": sample.networkBytesInPerSec,
                    "bytes_out_per_sec": sample.networkBytesOutPerSec
                ],
                "thermal_pressure": sample.thermalPressure.rawValue
            ]
        }

        // Manual JSON encoding since we have nested dictionaries
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "[]"
    }

    /// Save export data to file with save panel
    func saveToFile(_ content: String, defaultName: String, fileType: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = fileType == "csv" ? [.commaSeparatedText] : [.json]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    /// Copy export data to clipboard
    func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }

    /// Generate default filename with timestamp
    func defaultFilename(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return "silimon_export_\(formatter.string(from: Date())).\(format)"
    }
}
