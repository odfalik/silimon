import Foundation
import IOReportLib

/// Print and flush to ensure output appears immediately
private func debugPrint(_ message: String) {
    print(message)
    fflush(stdout)
}

/// Runs Silimon in debug mode, printing metrics to console for validation
func runDebugMode() {
    debugPrint("Silimon Debug Mode")
    debugPrint("==================")
    debugPrint("Press Ctrl+C to exit\n")

    // Initialize services
    let ioReportService = IOReportService(samplingDurationMs: 100)
    let memoryStats = MemoryStats()
    let batteryStats = BatteryStats()
    let networkStats = NetworkStats()

    // Initialize IOReport
    debugPrint("Initializing IOReport...")
    if ioReportService.initialize() {
        debugPrint("[OK] IOReport initialized successfully")
    } else {
        debugPrint("[FAIL] IOReport failed to initialize - power metrics will not be available")
    }

    debugPrint("\nStarting metrics collection (1 second intervals)...\n")
    debugPrint(String(repeating: "-", count: 80))

    // Handle Ctrl+C gracefully
    signal(SIGINT) { _ in
        debugPrint("\n\nExiting debug mode...")
        exit(0)
    }

    var sampleCount = 0

    // Collection loop
    while true {
        sampleCount += 1
        let timestamp = ISO8601DateFormatter().string(from: Date())

        debugPrint("\n[\(sampleCount)] \(timestamp)")
        debugPrint(String(repeating: "-", count: 80))

        // IOReport metrics (power, CPU, GPU)
        if let sample = ioReportService.sample() {
            debugPrint("\n  POWER:")
            debugPrint("    Package:  \(String(format: "%6.2f", sample.packagePower)) W")
            debugPrint("    CPU:      \(String(format: "%6.2f", sample.cpuPower)) W")
            debugPrint("    GPU:      \(String(format: "%6.2f", sample.gpuPower)) W")
            debugPrint("    ANE:      \(String(format: "%6.2f", sample.anePower)) W")

            debugPrint("\n  CPU CLUSTERS:")
            debugPrint("    E-cores:  \(String(format: "%5.1f", sample.eCoreUsage))% @ \(Int(sample.eCoreFreqMHz)) MHz")
            debugPrint("    P-cores:  \(String(format: "%5.1f", sample.pCoreUsage))% @ \(Int(sample.pCoreFreqMHz)) MHz")

            debugPrint("\n  GPU:")
            debugPrint("    Usage:    \(String(format: "%5.1f", sample.gpuUsage))% @ \(Int(sample.gpuFreqMHz)) MHz")

            debugPrint("\n  THERMAL:")
            debugPrint("    Pressure: \(sample.thermalPressure)")
        } else {
            debugPrint("\n  [!] IOReport sample failed - no power/CPU/GPU data")
        }

        // Memory metrics
        let memory = memoryStats.collect()
        debugPrint("\n  MEMORY:")
        debugPrint("    Used:     \(String(format: "%5.2f", memory.usedGB)) GB / \(String(format: "%.0f", memory.totalGB)) GB (\(String(format: "%.1f", memory.usedGB / memory.totalGB * 100))%)")
        debugPrint("    Pressure: \(memory.pressure)")
        debugPrint("    Swap:     \(String(format: "%5.2f", memory.swapGB)) GB")

        // Battery metrics
        let battery = batteryStats.collect()
        if battery.level > 0 {
            debugPrint("\n  BATTERY:")
            debugPrint("    Level:    \(String(format: "%5.1f", battery.level))%")
            debugPrint("    Charging: \(battery.isCharging ? "Yes" : "No")")
            if let timeRemaining = battery.timeRemaining {
                let hours = timeRemaining / 60
                let mins = timeRemaining % 60
                debugPrint("    Time:     \(hours)h \(mins)m \(battery.isCharging ? "to full" : "remaining")")
            }
        } else {
            debugPrint("\n  BATTERY: Not available (desktop Mac)")
        }

        // Network metrics
        let network = networkStats.collect()
        debugPrint("\n  NETWORK:")
        debugPrint("    Download: \(formatBytes(network.bytesInPerSec))/s")
        debugPrint("    Upload:   \(formatBytes(network.bytesOutPerSec))/s")

        debugPrint(String(repeating: "-", count: 80))

        // Wait 1 second before next sample
        Thread.sleep(forTimeInterval: 1.0)
    }
}

private func formatBytes(_ bytes: Double) -> String {
    if bytes < 1024 {
        return String(format: "%.0f B", bytes)
    } else if bytes < 1024 * 1024 {
        return String(format: "%.1f KB", bytes / 1024)
    } else if bytes < 1024 * 1024 * 1024 {
        return String(format: "%.2f MB", bytes / (1024 * 1024))
    } else {
        return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
    }
}
