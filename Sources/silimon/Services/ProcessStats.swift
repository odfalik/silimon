import Foundation

/// Information about a process's resource usage
struct AppProcessInfo: Identifiable {
    let id: Int32  // PID
    let name: String
    let cpuPercent: Double
    let memoryMB: Double

    var displayName: String {
        // Clean up common process names
        let cleaned = name
            .replacingOccurrences(of: " Helper", with: "")
            .replacingOccurrences(of: " (Renderer)", with: "")
            .replacingOccurrences(of: ".app", with: "")
        return cleaned
    }
}

/// Collects per-process resource usage statistics
class ProcessStats {
    struct TopProcesses {
        var byCPU: [AppProcessInfo] = []
        var byMemory: [AppProcessInfo] = []
    }

    /// Get top processes by CPU and memory usage
    func getTopProcesses(limit: Int = 5) -> TopProcesses {
        var result = TopProcesses()

        // Use `ps` command to get process info
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-Aceo", "pid,pcpu,rss,comm"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return result }

            var processes: [AppProcessInfo] = []

            for line in output.components(separatedBy: "\n").dropFirst() {  // Skip header
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }

                // Parse: PID CPU RSS COMMAND
                let components = trimmed.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
                guard components.count >= 4,
                      let pid = Int32(components[0]),
                      let cpu = Double(components[1]),
                      let rss = Double(components[2]) else { continue }

                let command = String(components[3])

                // Skip kernel/system processes
                guard !command.hasPrefix("kernel_") &&
                      command != "launchd" &&
                      !command.hasPrefix("com.apple.") else { continue }

                let process = AppProcessInfo(
                    id: pid,
                    name: command,
                    cpuPercent: cpu,
                    memoryMB: rss / 1024  // RSS is in KB
                )

                processes.append(process)
            }

            // Sort and get top by CPU
            result.byCPU = processes
                .sorted { $0.cpuPercent > $1.cpuPercent }
                .prefix(limit)
                .map { $0 }

            // Sort and get top by memory
            result.byMemory = processes
                .sorted { $0.memoryMB > $1.memoryMB }
                .prefix(limit)
                .map { $0 }

        } catch {
            // Silent failure
        }

        return result
    }

    /// Format memory as human-readable string
    static func formatMemory(_ mb: Double) -> String {
        if mb < 1024 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.1f GB", mb / 1024)
        }
    }

    /// Format CPU percentage
    static func formatCPU(_ percent: Double) -> String {
        String(format: "%.1f%%", percent)
    }
}
