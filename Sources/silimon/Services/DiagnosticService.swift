import Foundation
import IOKit.ps
import IOReportLib

/// Status of a diagnostic check
enum DiagnosticStatus: String {
    case pass = "PASS"
    case warning = "WARN"
    case fail = "FAIL"
}

/// Result of a single diagnostic check
struct DiagnosticResult {
    let name: String
    let status: DiagnosticStatus
    let message: String
    let suggestion: String?
}

/// System information for the diagnostic report
struct SystemInfo {
    let macOSVersion: String
    let architecture: String
    let chipModel: String
    let silimonVersion: String
}

/// Complete diagnostic report
struct DiagnosticReport {
    let timestamp: Date
    let systemInfo: SystemInfo
    let checks: [DiagnosticResult]

    var hasFailures: Bool { checks.contains { $0.status == .fail } }
    var hasWarnings: Bool { checks.contains { $0.status == .warning } }
}

/// Service for running system diagnostics
class DiagnosticService {
    static let shared = DiagnosticService()

    private init() {}

    /// Run all diagnostic checks and return a report
    func runDiagnostics() -> DiagnosticReport {
        let systemInfo = collectSystemInfo()
        var checks: [DiagnosticResult] = []

        checks.append(checkMacOSVersion())
        checks.append(checkArchitecture())
        checks.append(checkIOReportAvailability())
        checks.append(checkIOReportInitialization())
        checks.append(checkVmStatCommand())
        checks.append(checkMemoryPressureCommand())
        checks.append(checkSysctlCommand())
        checks.append(checkNetworkInterfaces())
        checks.append(checkBatteryAccess())

        return DiagnosticReport(
            timestamp: Date(),
            systemInfo: systemInfo,
            checks: checks
        )
    }

    // MARK: - System Info Collection

    private func collectSystemInfo() -> SystemInfo {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"

        #if arch(arm64)
        let arch = "arm64"
        #elseif arch(x86_64)
        let arch = "x86_64"
        #else
        let arch = "unknown"
        #endif

        return SystemInfo(
            macOSVersion: versionString,
            architecture: arch,
            chipModel: getChipModel(),
            silimonVersion: version
        )
    }

    private func getChipModel() -> String {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    // MARK: - Individual Checks

    private func checkMacOSVersion() -> DiagnosticResult {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        if osVersion.majorVersion >= 13 {
            return DiagnosticResult(
                name: "macOS Version",
                status: .pass,
                message: "\(osVersion.majorVersion).\(osVersion.minorVersion) meets minimum (13.0)",
                suggestion: nil
            )
        } else {
            return DiagnosticResult(
                name: "macOS Version",
                status: .fail,
                message: "\(osVersion.majorVersion).\(osVersion.minorVersion) is below minimum (13.0)",
                suggestion: "Silimon requires macOS Ventura (13.0) or later"
            )
        }
    }

    private func checkArchitecture() -> DiagnosticResult {
        #if arch(arm64)
        return DiagnosticResult(
            name: "Architecture",
            status: .pass,
            message: "Apple Silicon (arm64)",
            suggestion: nil
        )
        #else
        return DiagnosticResult(
            name: "Architecture",
            status: .fail,
            message: "Intel (x86_64)",
            suggestion: "Silimon only supports Apple Silicon Macs (M1, M2, M3, M4)"
        )
        #endif
    }

    private func checkIOReportAvailability() -> DiagnosticResult {
        if isIOReportAvailable() {
            return DiagnosticResult(
                name: "IOReport API",
                status: .pass,
                message: "Available",
                suggestion: nil
            )
        } else {
            return DiagnosticResult(
                name: "IOReport API",
                status: .fail,
                message: "Not available",
                suggestion: "IOReport framework not found. Power metrics will not work."
            )
        }
    }

    private func checkIOReportInitialization() -> DiagnosticResult {
        // Just check if the API is available - don't actually initialize
        // because IOReport uses global state that MetricsCollector is actively using.
        // Trying to access it from another thread causes deadlocks.
        if IOReportService.isAvailable {
            return DiagnosticResult(
                name: "IOReport Init",
                status: .pass,
                message: "API available",
                suggestion: nil
            )
        } else {
            return DiagnosticResult(
                name: "IOReport Init",
                status: .fail,
                message: "API not available",
                suggestion: "IOReport framework not accessible. Power metrics may not work."
            )
        }
    }

    private func checkVmStatCommand() -> DiagnosticResult {
        let path = "/usr/bin/vm_stat"
        if FileManager.default.isExecutableFile(atPath: path) {
            // Try to run it
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    return DiagnosticResult(
                        name: "vm_stat",
                        status: .pass,
                        message: "Available and working",
                        suggestion: nil
                    )
                }
            } catch {}
        }

        return DiagnosticResult(
            name: "vm_stat",
            status: .warning,
            message: "Not found or not executable",
            suggestion: "Memory metrics may not be available"
        )
    }

    private func checkMemoryPressureCommand() -> DiagnosticResult {
        let path = "/usr/bin/memory_pressure"
        if FileManager.default.isExecutableFile(atPath: path) {
            return DiagnosticResult(
                name: "memory_pressure",
                status: .pass,
                message: "Available",
                suggestion: nil
            )
        }

        return DiagnosticResult(
            name: "memory_pressure",
            status: .warning,
            message: "Not found",
            suggestion: "Memory pressure indicator may not work"
        )
    }

    private func checkSysctlCommand() -> DiagnosticResult {
        let path = "/usr/sbin/sysctl"
        if FileManager.default.isExecutableFile(atPath: path) {
            // Test with a simple query
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = ["hw.memsize"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    return DiagnosticResult(
                        name: "sysctl",
                        status: .pass,
                        message: "Available and working",
                        suggestion: nil
                    )
                }
            } catch {}
        }

        return DiagnosticResult(
            name: "sysctl",
            status: .warning,
            message: "Not found or not working",
            suggestion: "System info queries may fail"
        )
    }

    private func checkNetworkInterfaces() -> DiagnosticResult {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return DiagnosticResult(
                name: "Network",
                status: .warning,
                message: "Failed to get interfaces",
                suggestion: "Network metrics may not work"
            )
        }
        defer { freeifaddrs(ifaddr) }

        var count = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            if name != "lo0" && current.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                count += 1
            }
            ptr = current.pointee.ifa_next
        }

        if count > 0 {
            return DiagnosticResult(
                name: "Network",
                status: .pass,
                message: "Found \(count) interface(s)",
                suggestion: nil
            )
        } else {
            return DiagnosticResult(
                name: "Network",
                status: .warning,
                message: "No network interfaces found",
                suggestion: "Network throughput metrics will show 0"
            )
        }
    }

    private func checkBatteryAccess() -> DiagnosticResult {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return DiagnosticResult(
                name: "Battery",
                status: .warning,
                message: "Cannot access power sources",
                suggestion: "This is normal for Mac desktops without battery"
            )
        }

        // Check if any source is an internal battery
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               let type = info[kIOPSTypeKey] as? String,
               type == kIOPSInternalBatteryType {
                return DiagnosticResult(
                    name: "Battery",
                    status: .pass,
                    message: "Battery detected",
                    suggestion: nil
                )
            }
        }

        return DiagnosticResult(
            name: "Battery",
            status: .warning,
            message: "No internal battery found",
            suggestion: "This is normal for Mac desktops (Mac Studio, Mac mini, Mac Pro)"
        )
    }

    // MARK: - Report Formatting

    /// Format the report for CLI output
    func formatReportForCLI(_ report: DiagnosticReport) -> String {
        var output = ""

        output += "Silimon Diagnostic Report\n"
        output += "==========================\n"

        let formatter = ISO8601DateFormatter()
        output += "Timestamp: \(formatter.string(from: report.timestamp))\n"
        output += "\n"

        output += "System Information:\n"
        output += "  macOS Version: \(report.systemInfo.macOSVersion)\n"
        output += "  Architecture: \(report.systemInfo.architecture)\n"
        output += "  Chip: \(report.systemInfo.chipModel)\n"
        output += "  Silimon: v\(report.systemInfo.silimonVersion)\n"
        output += "\n"

        output += "Diagnostic Checks:\n"
        for check in report.checks {
            let icon = "[\(check.status.rawValue)]"
            output += "  \(icon) \(check.name): \(check.message)\n"
            if let suggestion = check.suggestion {
                output += "         \u{2192} \(suggestion)\n"
            }
        }

        output += "\n"
        if report.hasFailures {
            output += "Some checks FAILED. Please review the suggestions above.\n"
            output += "If issues persist, file a bug at: https://github.com/odfalik/silimon/issues\n"
        } else if report.hasWarnings {
            output += "Some checks have WARNINGS. Silimon should work but some features may be limited.\n"
        } else {
            output += "All checks PASSED. If you're still having issues, please file a bug report.\n"
        }

        return output
    }
}
