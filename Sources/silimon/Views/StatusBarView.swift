import AppKit

class StatusBarView: NSView, NSAccessibilityGroup {
    private var metrics: Metrics = .empty
    private var history: [Metrics] = []
    private var settings: Settings

    // MARK: - Accessibility

    override func isAccessibilityElement() -> Bool { true }

    override func accessibilityRole() -> NSAccessibility.Role? { .group }

    override func accessibilityLabel() -> String? {
        "Silimon system metrics"
    }

    override func accessibilityValue() -> Any? {
        buildAccessibilityDescription()
    }

    private func buildAccessibilityDescription() -> String {
        var parts: [String] = []

        for metric in settings.metricOrder where settings.isShownInBar(metric) {
            switch metric {
            case .power:
                parts.append("Power: \(Int(metrics.packagePower)) watts")
            case .cpu:
                parts.append("CPU: \(Int(max(metrics.eCoreUsage, metrics.pCoreUsage))) percent")
            case .gpu:
                parts.append("GPU: \(Int(metrics.gpuUsage)) percent")
            case .memory:
                parts.append("Memory: \(Int(metrics.memoryUsagePercent)) percent")
            case .network:
                parts.append("Network download: \(NetworkStats.formatBytesPerSec(metrics.networkBytesInPerSec))")
            case .battery:
                parts.append("Battery: \(Int(metrics.batteryLevel)) percent\(metrics.batteryIsCharging ? ", charging" : "")")
            }
        }

        return parts.isEmpty ? "No metrics displayed" : parts.joined(separator: ", ")
    }

    private let menuBarHeight: CGFloat = 22
    private let pillHeight: CGFloat = 16
    private let pillPadding: CGFloat = 4
    private let pillSpacing: CGFloat = 6
    private let cornerRadius: CGFloat = 4
    private let textPadding: CGFloat = 6
    private let iconSize: CGFloat = 10
    private let iconTextSpacing: CGFloat = 3

    // Sparkline dimensions
    private var sparklineWidth: CGFloat { settings.sparklineWidth.pixels }
    private let sparklineHeight: CGFloat = 22  // Full menu bar height

    init(settings: Settings) {
        self.settings = settings
        super.init(frame: .zero)
        updateSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(metrics: Metrics, history: [Metrics] = []) {
        self.metrics = metrics
        self.history = history
        updateSize()
        needsDisplay = true
    }

    private func updateSize() {
        var totalWidth: CGFloat

        if settings.statusBarMode == .sparkline {
            // Sparkline mode: single compact area
            totalWidth = pillPadding + sparklineWidth + pillPadding
        } else {
            // Text mode: pills with values
            let items = buildItems()
            totalWidth = pillPadding

            let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

            for (index, item) in items.enumerated() {
                let textWidth = (item.text as NSString).size(withAttributes: [.font: font]).width
                // icon + spacing + text + padding on both sides
                totalWidth += iconSize + iconTextSpacing + textWidth + textPadding * 2
                if index < items.count - 1 {
                    totalWidth += pillSpacing
                }
            }
            totalWidth += pillPadding

            if items.isEmpty {
                totalWidth = 0
            }
        }

        frame = NSRect(x: 0, y: 0, width: totalWidth, height: menuBarHeight)
    }

    private struct StatusItem {
        let text: String
        let icon: String
        let fillPercent: Double
        let color: NSColor
    }

    private func buildItems() -> [StatusItem] {
        var items: [StatusItem] = []
        // Figure space (U+2007) has the same width as digits
        let fs = "\u{2007}"
        let noData = "--"

        // Build items in the order specified by settings
        for metric in settings.metricOrder {
            guard settings.isShownInBar(metric) else { continue }

            let (hasData, rawValue, fillPercent, unit, icon, color) = metricData(for: metric)

            let text: String
            if hasData {
                let value = String(format: "%.0f", rawValue)
                text = String(repeating: fs, count: max(0, 3 - value.count)) + value + unit
            } else {
                text = fs + noData + unit
            }

            items.append(StatusItem(text: text, icon: icon, fillPercent: fillPercent, color: color))
        }

        return items
    }

    private func metricData(for metric: MetricType) -> (hasData: Bool, value: Double, fillPercent: Double, unit: String, icon: String, color: NSColor) {
        let color = settings.nsColor(for: metric)

        switch metric {
        case .power:
            let hasData = metrics.packagePower > 0
            let fillPercent = hasData ? min(metrics.packagePower / 100.0, 1.0) : 0
            return (hasData, metrics.packagePower, fillPercent, "W", "bolt.fill", color)

        case .memory:
            let hasData = metrics.memoryTotalGB > 0
            let fillPercent = hasData ? metrics.memoryUsagePercent / 100.0 : 0
            return (hasData, metrics.memoryUsagePercent, fillPercent, "%", "memorychip", color)

        case .cpu:
            let cpuUsage = max(metrics.eCoreUsage, metrics.pCoreUsage)
            let hasData = metrics.eCoreFrequencyMHz > 0 || metrics.pCoreFrequencyMHz > 0 || cpuUsage > 0
            let fillPercent = hasData ? cpuUsage / 100.0 : 0
            return (hasData, cpuUsage, fillPercent, "%", "cpu.fill", color)

        case .gpu:
            let hasData = metrics.gpuFrequencyMHz > 0 || metrics.gpuUsage > 0
            let fillPercent = hasData ? metrics.gpuUsage / 100.0 : 0
            return (hasData, metrics.gpuUsage, fillPercent, "%", "cpu", color)

        case .network:
            let totalBytesPerSec = metrics.networkBytesInPerSec + metrics.networkBytesOutPerSec
            let hasData = totalBytesPerSec > 0
            // Show download speed in KB/s or MB/s
            let displayValue: Double
            let unit: String
            if metrics.networkBytesInPerSec < 1024 * 1024 {
                displayValue = metrics.networkBytesInPerSec / 1024
                unit = "K"
            } else {
                displayValue = metrics.networkBytesInPerSec / 1024 / 1024
                unit = "M"
            }
            // Fill based on 10 MB/s max
            let fillPercent = hasData ? min(metrics.networkBytesInPerSec / (10 * 1024 * 1024), 1.0) : 0
            return (hasData, displayValue, fillPercent, unit, "arrow.down", color)

        case .battery:
            let hasData = metrics.batteryLevel > 0
            let fillPercent = hasData ? metrics.batteryLevel / 100.0 : 0
            let icon = metrics.batteryIsCharging ? "battery.100.bolt" : "battery.100"
            return (hasData, metrics.batteryLevel, fillPercent, "%", icon, color)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if settings.statusBarMode == .sparkline {
            drawSparklineMode()
        } else {
            drawTextMode()
        }
    }

    private func drawTextMode() {
        let items = buildItems()
        guard !items.isEmpty else { return }

        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        var xOffset: CGFloat = pillPadding
        let yOffset: CGFloat = (bounds.height - pillHeight) / 2

        for item in items {
            let textSize = (item.text as NSString).size(withAttributes: [.font: font])
            let pillWidth = iconSize + iconTextSpacing + textSize.width + textPadding * 2
            let pillRect = NSRect(x: xOffset, y: yOffset, width: pillWidth, height: pillHeight)

            // Draw background pill
            let bgColor = isDarkMode ? NSColor.white.withAlphaComponent(0.1) : NSColor.black.withAlphaComponent(0.08)
            let bgPath = NSBezierPath(roundedRect: pillRect, xRadius: cornerRadius, yRadius: cornerRadius)
            bgColor.setFill()
            bgPath.fill()

            // Draw fill based on percentage (from left)
            if item.fillPercent > 0 {
                let fillWidth = pillWidth * CGFloat(item.fillPercent)
                let fillRect = NSRect(x: xOffset, y: yOffset, width: fillWidth, height: pillHeight)

                // Clip to rounded rect
                NSGraphicsContext.saveGraphicsState()
                bgPath.addClip()

                let fillColor = item.color.withAlphaComponent(isDarkMode ? 0.5 : 0.35)
                fillColor.setFill()
                NSBezierPath(rect: fillRect).fill()

                NSGraphicsContext.restoreGraphicsState()
            }

            let textColor = isDarkMode ? NSColor.white : NSColor.black

            // Draw icon
            if let iconImage = NSImage(systemSymbolName: item.icon, accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
                let configuredImage = iconImage.withSymbolConfiguration(config)?
                    .tinted(with: textColor)
                let iconRect = NSRect(
                    x: xOffset + textPadding,
                    y: yOffset + (pillHeight - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                configuredImage?.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }

            // Draw text
            let textRect = NSRect(
                x: xOffset + textPadding + iconSize + iconTextSpacing,
                y: yOffset + (pillHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            (item.text as NSString).draw(in: textRect, withAttributes: attributes)

            xOffset += pillWidth + pillSpacing
        }
    }

    private func drawSparklineMode() {
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let yOffset: CGFloat = (bounds.height - sparklineHeight) / 2
        let sparklineRect = NSRect(x: pillPadding, y: yOffset, width: sparklineWidth, height: sparklineHeight)

        // Draw background - darker for better contrast with sparklines
        let bgColor = isDarkMode ? NSColor.white.withAlphaComponent(0.18) : NSColor.black.withAlphaComponent(0.12)
        let bgPath = NSBezierPath(roundedRect: sparklineRect, xRadius: cornerRadius, yRadius: cornerRadius)
        bgColor.setFill()
        bgPath.fill()

        // Clip to rounded rect for sparklines
        NSGraphicsContext.saveGraphicsState()
        bgPath.addClip()

        // Draw each enabled metric as an overlaid sparkline (respects menu bar toggle)
        let metricsToShow = settings.metricOrder.filter { settings.isShownInBar($0) }

        let inset: CGFloat = 1
        let drawRect = sparklineRect.insetBy(dx: inset, dy: 0)  // No vertical inset

        for metric in metricsToShow {
            guard !history.isEmpty else { continue }

            let color = settings.nsColor(for: metric)
            let maxValue = ChartConfig.maxValue(for: metric)
            let path = NSBezierPath()
            path.lineWidth = 1.0

            let pointCount = history.count
            let xStep = drawRect.width / CGFloat(max(pointCount - 1, 1))

            for (index, sample) in history.enumerated() {
                let value = ChartConfig.value(from: sample, for: metric)
                let normalizedValue = min(value / maxValue, 1.0)
                let x = drawRect.minX + CGFloat(index) * xStep
                let y = drawRect.minY + CGFloat(normalizedValue) * drawRect.height

                if index == 0 {
                    path.move(to: NSPoint(x: x, y: y))
                } else {
                    path.line(to: NSPoint(x: x, y: y))
                }
            }

            color.withAlphaComponent(isDarkMode ? 0.9 : 0.7).setStroke()
            path.stroke()
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
