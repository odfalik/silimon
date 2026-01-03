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
    private let updateChecker = UpdateChecker.shared
    private var cancellables = Set<AnyCancellable>()
    private var statusBarView: StatusBarView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the metrics collector with settings
        metricsCollector = MetricsCollector(settings: settings)

        // Create the status bar view
        statusBarView = StatusBarView(settings: settings)

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self

            // Add custom status bar view
            button.addSubview(statusBarView)
            updateStatusBar()
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                metricsCollector: metricsCollector,
                settings: settings,
                updateChecker: updateChecker,
                onSettingsChanged: { [weak self] in
                    self?.handleSettingsChanged()
                }
            )
        )

        // Start collecting metrics
        metricsCollector.start()

        // Start checking for updates
        updateChecker.startPeriodicChecks()

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
            .merge(with: settings.$showBatteryInStatusBar)
            .sink { [weak self] _ in
                self?.updateStatusBar()
            }
            .store(in: &cancellables)

        // Observe status bar mode changes
        settings.$statusBarMode
            .sink { [weak self] _ in
                self?.updateStatusBar()
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
            self?.updateStatusBar()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        metricsCollector.stop()
        updateChecker.stopPeriodicChecks()
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

    private func updateStatusBar() {
        guard statusItem.button != nil else { return }

        let metrics = metricsCollector.currentMetrics
        let history = metricsCollector.history.samples

        // Update the custom status bar view
        statusBarView.update(metrics: metrics, history: history)

        // Position the status bar view
        statusBarView.frame.origin = .zero

        // Update the status item width to fit the custom view
        statusItem.length = statusBarView.frame.width
    }
}
