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
    private let iconSize: CGFloat = 10
    private let iconTextSpacing: CGFloat = 3

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

        if settings.showPowerInStatusBar {
            let hasData = metrics.packagePower > 0
            let fillPercent = hasData ? min(metrics.packagePower / 100.0, 1.0) : 0
            let text: String
            if hasData {
                let value = String(format: "%.0f", metrics.packagePower)
                text = String(repeating: fs, count: max(0, 3 - value.count)) + value + "W"
            } else {
                text = fs + noData + "W"
            }
            items.append(StatusItem(text: text, icon: "bolt.fill", fillPercent: fillPercent, color: powerColor))
        }

        if settings.showMemoryInStatusBar {
            let hasData = metrics.memoryTotalGB > 0
            let fillPercent = hasData ? metrics.memoryUsagePercent / 100.0 : 0
            let text: String
            if hasData {
                let value = String(format: "%.0f", metrics.memoryUsagePercent)
                text = String(repeating: fs, count: max(0, 3 - value.count)) + value + "%"
            } else {
                text = fs + noData + "%"
            }
            items.append(StatusItem(text: text, icon: "memorychip", fillPercent: fillPercent, color: memoryColor))
        }

        if settings.showCPUInStatusBar {
            let cpuUsage = max(metrics.eCoreUsage, metrics.pCoreUsage)
            let hasData = metrics.eCoreFrequencyMHz > 0 || metrics.pCoreFrequencyMHz > 0 || cpuUsage > 0
            let fillPercent = hasData ? cpuUsage / 100.0 : 0
            let text: String
            if hasData {
                let value = String(format: "%.0f", cpuUsage)
                text = String(repeating: fs, count: max(0, 3 - value.count)) + value + "%"
            } else {
                text = fs + noData + "%"
            }
            items.append(StatusItem(text: text, icon: "cpu.fill", fillPercent: fillPercent, color: cpuColor))
        }

        if settings.showGPUInStatusBar {
            let hasData = metrics.gpuFrequencyMHz > 0 || metrics.gpuUsage > 0
            let fillPercent = hasData ? metrics.gpuUsage / 100.0 : 0
            let text: String
            if hasData {
                let value = String(format: "%.0f", metrics.gpuUsage)
                text = String(repeating: fs, count: max(0, 3 - value.count)) + value + "%"
            } else {
                text = fs + noData + "%"
            }
            items.append(StatusItem(text: text, icon: "cpu", fillPercent: fillPercent, color: gpuColor))
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
