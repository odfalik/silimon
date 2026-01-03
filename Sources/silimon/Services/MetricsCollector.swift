import Foundation
import Combine

/// Main orchestrator for collecting system metrics
class MetricsCollector: ObservableObject {
    @Published private(set) var history = MetricsHistory()
    @Published private(set) var currentMetrics = Metrics.empty
    @Published private(set) var isCollecting = false
    @Published private(set) var error: String?
    @Published private(set) var isLowPowerMode = false

    private var timer: Timer?
    private let memoryStats = MemoryStats()
    private let powerMetricsParser = PowerMetricsParser()
    private var powerMetricsProcess: Process?
    private var tempFile: URL?
    private var powerStateObserver: NSObjectProtocol?

    private let settings: Settings

    /// Multiplier for sampling interval when in low power mode
    private let lowPowerMultiplier: Double = 2.0

    init(settings: Settings = .shared) {
        self.settings = settings
        setupPowerStateObserver()
        updateLowPowerState()
    }

    private func setupPowerStateObserver() {
        powerStateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerStateChange()
        }
    }

    private func updateLowPowerState() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private func handlePowerStateChange() {
        let wasLowPower = isLowPowerMode
        updateLowPowerState()

        // Restart timer with new interval if power state changed
        if wasLowPower != isLowPowerMode && isCollecting {
            startTimer()
        }
    }

    /// Effective sampling interval, accounting for low power mode
    var effectiveSamplingInterval: TimeInterval {
        isLowPowerMode ? settings.samplingInterval * lowPowerMultiplier : settings.samplingInterval
    }

    func start() {
        guard !isCollecting else { return }
        isCollecting = true
        error = nil

        // Start powermetrics process if needed
        if settings.needsPowerMetrics {
            startPowerMetrics()
        }

        // Start polling timer with configured interval
        startTimer()

        // Collect first sample immediately
        collectSample()
    }

    func stop() {
        isCollecting = false
        timer?.invalidate()
        timer = nil
        stopPowerMetrics()
    }

    /// Called when settings change - restarts collection with new settings
    func restart() {
        stop()
        start()
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = effectiveSamplingInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.collectSample()
        }
        timer?.tolerance = interval * 0.1
    }

    private func collectSample() {
        var metrics = Metrics(timestamp: Date())

        // Collect memory stats (no sudo needed) - only if memory module is enabled
        if settings.memoryModuleEnabled {
            let memStats = memoryStats.collect()
            metrics.memoryUsedGB = memStats.usedGB
            metrics.memoryTotalGB = memStats.totalGB
            metrics.memoryPressure = memStats.pressure
            metrics.swapUsedGB = memStats.swapGB
        }

        // Read powermetrics data if available and any relevant module is enabled
        if settings.needsPowerMetrics,
           let tempFile = tempFile,
           let powerData = powerMetricsParser.parse(from: tempFile) {
            if settings.gpuModuleEnabled {
                metrics.gpuUsage = powerData.gpuUsage
                metrics.gpuFrequencyMHz = powerData.gpuFrequencyMHz
                metrics.gpuPower = powerData.gpuPower
            }
            if settings.cpuModuleEnabled {
                metrics.eCoreUsage = powerData.eCoreUsage
                metrics.pCoreUsage = powerData.pCoreUsage
                metrics.eCoreFrequencyMHz = powerData.eCoreFrequencyMHz
                metrics.pCoreFrequencyMHz = powerData.pCoreFrequencyMHz
                metrics.cpuPower = powerData.cpuPower
            }
            if settings.powerModuleEnabled {
                metrics.packagePower = powerData.packagePower
                metrics.anePower = powerData.anePower
            }
            metrics.thermalPressure = powerData.thermalPressure
        }

        // Update published properties on main thread
        DispatchQueue.main.async {
            self.currentMetrics = metrics
            self.history.add(metrics)
        }
    }

    // MARK: - PowerMetrics Process Management

    private func startPowerMetrics() {
        // Create temp file for output
        let tempDir = FileManager.default.temporaryDirectory
        tempFile = tempDir.appendingPathComponent("silimon_metrics_\(ProcessInfo.processInfo.processIdentifier).plist")

        guard let tempFile = tempFile else { return }

        // Remove any existing temp file
        try? FileManager.default.removeItem(at: tempFile)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [
            "nice", "-n", "10",
            "/usr/bin/powermetrics",
            "--samplers", "cpu_power,gpu_power,thermal",
            "-f", "plist",
            "-i", "1000",  // 1 second interval
            "-o", tempFile.path
        ]

        // Suppress output
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            powerMetricsProcess = process
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to start powermetrics: \(error.localizedDescription). Run 'sudo silimon' or set up passwordless sudo."
            }
        }
    }

    private func stopPowerMetrics() {
        if let process = powerMetricsProcess, process.isRunning {
            process.terminate()
        }
        powerMetricsProcess = nil

        // Clean up temp file
        if let tempFile = tempFile {
            try? FileManager.default.removeItem(at: tempFile)
        }
        tempFile = nil
    }

    deinit {
        stop()
        if let observer = powerStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
