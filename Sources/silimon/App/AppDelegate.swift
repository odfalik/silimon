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

        // Figure space (U+2007) has the same width as digits in tabular fonts
        let figureSpace = "\u{2007}"

        // Build status bar text based on enabled options
        // Use fixed-width number formatting to prevent width changes
        // Always show enabled metrics to maintain consistent width
        if settings.showPowerInStatusBar {
            parts.append(padWithFigureSpaces(String(format: "%.1fW", metrics.packagePower), toLength: 6, figureSpace: figureSpace))
        }

        if settings.showMemoryInStatusBar {
            parts.append(padWithFigureSpaces(String(format: "%.1fGB", metrics.memoryUsedGB), toLength: 7, figureSpace: figureSpace))
        }

        if settings.showCPUInStatusBar {
            let cpuUsage = max(metrics.eCoreUsage, metrics.pCoreUsage)
            parts.append("CPU" + padWithFigureSpaces(String(format: "%.0f%%", cpuUsage), toLength: 4, figureSpace: figureSpace))
        }

        if settings.showGPUInStatusBar {
            parts.append("GPU" + padWithFigureSpaces(String(format: "%.0f%%", metrics.gpuUsage), toLength: 4, figureSpace: figureSpace))
        }

        if parts.isEmpty {
            button.attributedTitle = NSAttributedString(string: "")
        } else {
            let text = " " + parts.joined(separator: " | ")
            // Use monospaced digits to keep consistent width as numbers change
            let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        }
    }

    private func padWithFigureSpaces(_ string: String, toLength length: Int, figureSpace: String) -> String {
        let padding = length - string.count
        if padding > 0 {
            return String(repeating: figureSpace, count: padding) + string
        }
        return string
    }
}
