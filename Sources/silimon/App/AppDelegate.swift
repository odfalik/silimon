import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var metricsCollector: MetricsCollector!
    private var eventMonitor: Any?
    private var statusBarTimer: Timer?
    private let settings = Settings.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the metrics collector with settings
        metricsCollector = MetricsCollector(settings: settings)

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Silimon")
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusBarText()
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                metricsCollector: metricsCollector,
                settings: settings,
                onSettingsChanged: { [weak self] in
                    self?.handleSettingsChanged()
                }
            )
        )

        // Start collecting metrics
        metricsCollector.start()

        // Update status bar periodically
        startStatusBarTimer()

        // Monitor for clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }

        // Listen for settings changes that affect status bar display
        observeStatusBarSettings()
    }

    private func observeStatusBarSettings() {
        // Observe changes to status bar display settings
        settings.$showPowerInStatusBar
            .merge(with: settings.$showMemoryInStatusBar)
            .merge(with: settings.$showCPUInStatusBar)
            .merge(with: settings.$showGPUInStatusBar)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)
    }

    private func handleSettingsChanged() {
        // Restart metrics collector with new settings
        metricsCollector.restart()

        // Restart status bar timer with new interval
        startStatusBarTimer()
    }

    private func startStatusBarTimer() {
        statusBarTimer?.invalidate()
        statusBarTimer = Timer.scheduledTimer(withTimeInterval: settings.samplingInterval, repeats: true) { [weak self] _ in
            self?.updateStatusBarText()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        metricsCollector.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Bring popover to front
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateStatusBarText() {
        guard let button = statusItem.button else { return }

        let metrics = metricsCollector.currentMetrics
        var parts: [String] = []

        // Build status bar text based on enabled options
        if settings.showPowerInStatusBar && metrics.packagePower > 0 {
            parts.append(String(format: "%.1fW", metrics.packagePower))
        }

        if settings.showMemoryInStatusBar && metrics.memoryUsedGB > 0 {
            parts.append(String(format: "%.1fGB", metrics.memoryUsedGB))
        }

        if settings.showCPUInStatusBar {
            let cpuUsage = max(metrics.eCoreUsage, metrics.pCoreUsage)
            if cpuUsage > 0 {
                parts.append(String(format: "CPU %.0f%%", cpuUsage))
            }
        }

        if settings.showGPUInStatusBar && metrics.gpuUsage > 0 {
            parts.append(String(format: "GPU %.0f%%", metrics.gpuUsage))
        }

        if parts.isEmpty {
            button.title = ""
        } else {
            button.title = " " + parts.joined(separator: " | ")
        }
    }
}
