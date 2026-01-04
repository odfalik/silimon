import Foundation
import Combine

/// Main orchestrator for collecting system metrics
class MetricsCollector: ObservableObject {
    @Published private(set) var history = MetricsHistory()
    @Published private(set) var currentMetrics = Metrics.empty
    @Published private(set) var isCollecting = false
    @Published private(set) var error: String?
    @Published private(set) var isLowPowerMode = false
    @Published private(set) var collectionHealth = CollectionHealth()

    private var timer: Timer?
    private let memoryStats = MemoryStats()
    private let batteryStats = BatteryStats()
    private let networkStats = NetworkStats()
    private let ioReportService: IOReportService
    private var powerStateObserver: NSObjectProtocol?
    private let alertService = AlertService.shared

    private let settings: Settings

    /// Multiplier for sampling interval when in low power mode
    private let lowPowerMultiplier: Double = 2.0

    init(settings: Settings = .shared) {
        self.settings = settings
        // Use shorter sampling duration for IOReport (100ms is enough for accurate readings)
        self.ioReportService = IOReportService(samplingDurationMs: 100)
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

        // Update history duration from settings
        history.maxDuration = settings.historyDuration

        // Initialize IOReport if needed for power/CPU/GPU metrics
        if settings.needsPowerMetrics {
            if !ioReportService.initialize() {
                DispatchQueue.main.async {
                    self.error = "Failed to initialize IOReport. Power metrics may not be available."
                }
            }
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
        ioReportService.cleanup()
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

        // Collect memory stats - only if memory module is enabled
        if settings.memoryModuleEnabled {
            let memStats = memoryStats.collect()
            metrics.memoryUsedGB = memStats.usedGB
            metrics.memoryTotalGB = memStats.totalGB
            metrics.memoryPressure = memStats.pressure
            metrics.swapUsedGB = memStats.swapGB
        }

        // Collect battery stats - only if battery module is enabled
        if settings.batteryModuleEnabled {
            let batStats = batteryStats.collect()
            metrics.batteryLevel = batStats.level
            metrics.batteryIsCharging = batStats.isCharging
            metrics.batteryTimeRemaining = batStats.timeRemaining
        }

        // Collect network stats - only if network module is enabled
        if settings.networkModuleEnabled {
            let netStats = networkStats.collect()
            metrics.networkBytesInPerSec = netStats.bytesInPerSec
            metrics.networkBytesOutPerSec = netStats.bytesOutPerSec
        }

        // Collect power/CPU/GPU metrics via IOReport
        if settings.needsPowerMetrics, let sample = ioReportService.sample() {
            if settings.gpuModuleEnabled {
                metrics.gpuUsage = sample.gpuUsage
                metrics.gpuFrequencyMHz = sample.gpuFreqMHz
                metrics.gpuPower = sample.gpuPower
            }
            if settings.cpuModuleEnabled {
                metrics.eCoreUsage = sample.eCoreUsage
                metrics.pCoreUsage = sample.pCoreUsage
                metrics.eCoreFrequencyMHz = sample.eCoreFreqMHz
                metrics.pCoreFrequencyMHz = sample.pCoreFreqMHz
                metrics.cpuPower = sample.cpuPower
            }
            if settings.powerModuleEnabled {
                metrics.packagePower = sample.packagePower
                metrics.anePower = sample.anePower
            }
            metrics.thermalPressure = sample.thermalPressure
        }

        // Update published properties on main thread
        DispatchQueue.main.async {
            self.currentMetrics = metrics
            self.history.add(metrics)

            // Check for alerts
            self.alertService.checkMetrics(metrics)

            // Update collection health
            self.updateCollectionHealth(metrics)
        }
    }

    private func updateCollectionHealth(_ metrics: Metrics) {
        var health = CollectionHealth()

        // Power/CPU/GPU health based on whether we got valid IOReport data
        if settings.needsPowerMetrics {
            if metrics.packagePower > 0 || metrics.cpuPower > 0 {
                health.power = .healthy
                health.cpu = .healthy
                health.gpu = .healthy
            } else {
                health.power = CollectionHealth.ModuleHealth(status: .degraded, lastSuccess: nil, errorMessage: "No power data")
                health.cpu = CollectionHealth.ModuleHealth(status: .degraded, lastSuccess: nil, errorMessage: "No CPU data")
                health.gpu = CollectionHealth.ModuleHealth(status: .degraded, lastSuccess: nil, errorMessage: "No GPU data")
            }
        } else {
            health.power = .healthy
            health.cpu = .healthy
            health.gpu = .healthy
        }

        // Memory health
        if settings.memoryModuleEnabled {
            health.memory = metrics.memoryTotalGB > 0 ? .healthy : CollectionHealth.ModuleHealth(status: .degraded, lastSuccess: nil, errorMessage: "No memory data")
        } else {
            health.memory = .healthy
        }

        // Network health - always healthy if enabled (even 0 bytes is valid)
        health.network = .healthy

        // Battery health - healthy if we got any reading, or if no battery exists (desktop)
        if settings.batteryModuleEnabled {
            health.battery = .healthy  // Even 0% is valid for desktops
        } else {
            health.battery = .healthy
        }

        collectionHealth = health
    }

    deinit {
        stop()
        if let observer = powerStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
