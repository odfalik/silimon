import Foundation

/// Collects memory statistics using system commands (no sudo required)
struct MemoryStats {
    struct Result {
        var usedGB: Double = 0
        var totalGB: Double = 0
        var pressure: MemoryPressure = .nominal
        var swapGB: Double = 0
    }

    func collect() -> Result {
        var result = Result()

        // Get total memory from sysctl
        result.totalGB = getTotalMemory()

        // Get used memory from vm_stat
        result.usedGB = getUsedMemory()

        // Get memory pressure
        result.pressure = getMemoryPressure()

        // Get swap usage
        result.swapGB = getSwapUsage()

        return result
    }

    private func getTotalMemory() -> Double {
        var size: size_t = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
        return Double(totalMemory) / 1_073_741_824  // bytes to GB
    }

    private func getUsedMemory() -> Double {
        // Run vm_stat and parse output
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return 0 }

            return parseVmStat(output)
        } catch {
            return 0
        }
    }

    private func parseVmStat(_ output: String) -> Double {
        let pageSize: Double = 16384  // Apple Silicon uses 16KB pages

        var wired: Double = 0
        var active: Double = 0
        var compressed: Double = 0

        for line in output.components(separatedBy: "\n") {
            if line.contains("Pages wired down:") {
                wired = extractPages(from: line)
            } else if line.contains("Pages active:") {
                active = extractPages(from: line)
            } else if line.contains("Pages occupied by compressor:") {
                compressed = extractPages(from: line)
            }
        }

        let usedBytes = (wired + active + compressed) * pageSize
        return usedBytes / 1_073_741_824  // bytes to GB
    }

    private func extractPages(from line: String) -> Double {
        // Extract number from line like "Pages wired down:   123456."
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return 0 }

        let valueStr = components[1]
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")

        return Double(valueStr) ?? 0
    }

    private func getMemoryPressure() -> MemoryPressure {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/memory_pressure")

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return .nominal }

            if output.contains("critical") {
                return .critical
            } else if output.contains("warn") {
                return .warn
            } else {
                return .nominal
            }
        } catch {
            return .nominal
        }
    }

    private func getSwapUsage() -> Double {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/sysctl")
        task.arguments = ["vm.swapusage"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return 0 }

            // Parse "vm.swapusage: total = 2048.00M  used = 123.45M  free = 1924.55M"
            if let usedRange = output.range(of: "used = ") {
                let afterUsed = output[usedRange.upperBound...]
                if let endRange = afterUsed.range(of: "M") {
                    let valueStr = String(afterUsed[..<endRange.lowerBound])
                    if let valueMB = Double(valueStr.trimmingCharacters(in: .whitespaces)) {
                        return valueMB / 1024  // MB to GB
                    }
                }
            }
            return 0
        } catch {
            return 0
        }
    }
}
