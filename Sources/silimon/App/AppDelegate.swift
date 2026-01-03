import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var metricsCollector: MetricsCollector!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the metrics collector
        metricsCollector = MetricsCollector()

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
            rootView: PopoverView(metricsCollector: metricsCollector)
        )

        // Start collecting metrics
        metricsCollector.start()

        // Update status bar periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusBarText()
        }

        // Monitor for clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
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

        // Show power in menu bar (most unique metric vs Stats app)
        if metrics.packagePower > 0 {
            let powerStr = String(format: "%.1fW", metrics.packagePower)
            button.title = " \(powerStr)"
        } else if metrics.memoryUsedGB > 0 {
            // Fallback to memory if no power data yet
            let memStr = String(format: "%.1fGB", metrics.memoryUsedGB)
            button.title = " \(memStr)"
        } else {
            button.title = ""
        }
    }
}
