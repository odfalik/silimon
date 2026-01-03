import Foundation
import Darwin

/// Collects memory statistics using direct syscalls (no process spawning)
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

        // Get used memory using host_statistics64 (direct syscall, no subprocess)
        result.usedGB = getUsedMemoryDirect()

        // Get memory pressure from dispatch source (or fallback to command)
        result.pressure = getMemoryPressureDirect()

        // Get swap usage via sysctl (direct, no subprocess)
        result.swapGB = getSwapUsageDirect()

        return result
    }

    private func getTotalMemory() -> Double {
        var size: size_t = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
        return Double(totalMemory) / 1_073_741_824  // bytes to GB
    }

    /// Get used memory using host_statistics64 directly (no vm_stat subprocess)
    private func getUsedMemoryDirect() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            // Fallback to vm_stat command if direct call fails
            return getUsedMemoryFallback()
        }

        // Get page size
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        // Calculate used memory: wired + active + compressed
        let wiredBytes = UInt64(stats.wire_count) * UInt64(pageSize)
        let activeBytes = UInt64(stats.active_count) * UInt64(pageSize)
        let compressedBytes = UInt64(stats.compressor_page_count) * UInt64(pageSize)

        let usedBytes = wiredBytes + activeBytes + compressedBytes
        return Double(usedBytes) / 1_073_741_824  // bytes to GB
    }

    /// Fallback to vm_stat command if direct syscall fails
    private func getUsedMemoryFallback() -> Double {
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
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return 0 }

        let valueStr = components[1]
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")

        return Double(valueStr) ?? 0
    }

    /// Get memory pressure using dispatch_source (direct, no subprocess)
    private func getMemoryPressureDirect() -> MemoryPressure {
        // Use ProcessInfo's memory footprint as a proxy
        // This is lightweight and doesn't spawn processes
        let info = ProcessInfo.processInfo

        // Check thermal state as a proxy for memory pressure on Apple Silicon
        // High thermal state often correlates with memory pressure
        let thermalState = info.thermalState

        // Use physical memory and get current pressure via sysctl
        var pressure: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let result = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &size, nil, 0)

        if result == 0 {
            // Pressure levels: 1 = normal, 2 = warn, 4 = critical
            switch pressure {
            case 4:
                return .critical
            case 2:
                return .warn
            default:
                return .nominal
            }
        }

        // Fallback: use thermal state as proxy
        if thermalState == .serious || thermalState == .critical {
            return .warn
        }

        return .nominal
    }

    /// Get swap usage via sysctl directly (no subprocess)
    private func getSwapUsageDirect() -> Double {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size

        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)

        guard result == 0 else {
            // Fallback to command if sysctl fails
            return getSwapUsageFallback()
        }

        // xsu_used is in bytes
        return Double(swapUsage.xsu_used) / 1_073_741_824  // bytes to GB
    }

    /// Fallback to sysctl command
    private func getSwapUsageFallback() -> Double {
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

            if let usedRange = output.range(of: "used = ") {
                let afterUsed = output[usedRange.upperBound...]
                if let endRange = afterUsed.range(of: "M") {
                    let valueStr = String(afterUsed[..<endRange.lowerBound])
                    if let valueMB = Double(valueStr.trimmingCharacters(in: .whitespaces)) {
                        return valueMB / 1024
                    }
                }
            }
            return 0
        } catch {
            return 0
        }
    }
}
