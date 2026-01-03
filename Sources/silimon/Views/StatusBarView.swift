import AppKit

class StatusBarView: NSView {
    private var metrics: Metrics = .empty
    private var settings: Settings

    // Colors for each metric type
    private let powerColor = NSColor.systemOrange
    private let memoryColor = NSColor.systemPurple
    private let cpuColor = NSColor.systemBlue
    private let gpuColor = NSColor.systemGreen

    private let menuBarHeight: CGFloat = 22
    private let pillHeight: CGFloat = 16
    private let pillPadding: CGFloat = 4
    private let pillSpacing: CGFloat = 6
    private let cornerRadius: CGFloat = 4
    private let textPadding: CGFloat = 6

    init(settings: Settings) {
        self.settings = settings
        super.init(frame: .zero)
        updateSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(metrics: Metrics) {
        self.metrics = metrics
        updateSize()
        needsDisplay = true
    }

    private func updateSize() {
        let items = buildItems()
        var totalWidth: CGFloat = pillPadding

        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

        for (index, item) in items.enumerated() {
            let textWidth = (item.text as NSString).size(withAttributes: [.font: font]).width
            totalWidth += textWidth + textPadding * 2
            if index < items.count - 1 {
                totalWidth += pillSpacing
            }
        }
        totalWidth += pillPadding

        if items.isEmpty {
            totalWidth = 0
        }

        frame = NSRect(x: 0, y: 0, width: totalWidth, height: menuBarHeight)
    }

    private struct StatusItem {
        let text: String
        let fillPercent: Double
        let color: NSColor
    }

    private func buildItems() -> [StatusItem] {
        var items: [StatusItem] = []
        // Figure space (U+2007) has the same width as digits
        let fs = "\u{2007}"

        if settings.showPowerInStatusBar {
            // Power: assume 100W as max for fill calculation
            let fillPercent = min(metrics.packagePower / 100.0, 1.0)
            // Fixed width: up to 999W (3 digits)
            let value = String(format: "%.0f", metrics.packagePower)
            let padded = String(repeating: fs, count: max(0, 3 - value.count)) + value
            items.append(StatusItem(text: padded + "W", fillPercent: fillPercent, color: powerColor))
        }

        if settings.showMemoryInStatusBar {
            let fillPercent = metrics.memoryUsagePercent / 100.0
            // Fixed width: 0-100% (3 digits)
            let value = String(format: "%.0f", metrics.memoryUsagePercent)
            let padded = String(repeating: fs, count: max(0, 3 - value.count)) + value
            items.append(StatusItem(text: padded + "%", fillPercent: fillPercent, color: memoryColor))
        }

        if settings.showCPUInStatusBar {
            let cpuUsage = max(metrics.eCoreUsage, metrics.pCoreUsage)
            let fillPercent = cpuUsage / 100.0
            // Fixed width: 0-100% (3 digits)
            let value = String(format: "%.0f", cpuUsage)
            let padded = String(repeating: fs, count: max(0, 3 - value.count)) + value
            items.append(StatusItem(text: "C" + padded + "%", fillPercent: fillPercent, color: cpuColor))
        }

        if settings.showGPUInStatusBar {
            let fillPercent = metrics.gpuUsage / 100.0
            // Fixed width: 0-100% (3 digits)
            let value = String(format: "%.0f", metrics.gpuUsage)
            let padded = String(repeating: fs, count: max(0, 3 - value.count)) + value
            items.append(StatusItem(text: "G" + padded + "%", fillPercent: fillPercent, color: gpuColor))
        }

        return items
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let items = buildItems()
        guard !items.isEmpty else { return }

        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        var xOffset: CGFloat = pillPadding
        let yOffset: CGFloat = (bounds.height - pillHeight) / 2

        for item in items {
            let textSize = (item.text as NSString).size(withAttributes: [.font: font])
            let pillWidth = textSize.width + textPadding * 2
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

            // Draw text
            let textColor = isDarkMode ? NSColor.white : NSColor.black
            let textRect = NSRect(
                x: xOffset + textPadding,
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
}
