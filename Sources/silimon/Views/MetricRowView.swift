import SwiftUI
import Charts

struct MetricRowView: View {
    let metric: MetricType
    let metrics: Metrics
    let samples: [Metrics]  // Direct array instead of @ObservedObject
    @ObservedObject var settings: Settings
    let isSettingsMode: Bool
    var onSettingsChanged: () -> Void

    private var color: Color {
        settings.color(for: metric)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Drag handle - only rendered in settings mode
            if isSettingsMode {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 28)
            }

            // Left side: stats - use HStack+Spacer to force left alignment
            HStack(spacing: 0) {
                statsView
                Spacer(minLength: 0)
            }
            .frame(width: 100)

            // Right side: chart or settings pills
            if isSettingsMode {
                settingsView
            } else {
                chartView
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Color(NSColor.controlBackgroundColor)
                dangerColor.opacity(dangerLevel * 0.06)
            }
        )
        .cornerRadius(10)
    }

    // MARK: - Stats View

    @ViewBuilder
    private var statsView: some View {
        switch metric {
        case .power:
            powerStats
        case .memory:
            memoryStats
        case .cpu:
            cpuStats
        case .gpu:
            gpuStats
        case .network:
            networkStats
        case .battery:
            batteryStats
        }
    }

    private static let iconWidth: CGFloat = 14

    private var powerStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("Power")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .tooltip("Total SoC power consumption. Idle: 2-5W, Heavy use: 20-40W")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", metrics.packagePower))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("W")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 6) {
                PowerBreakdownItem(label: "CPU", value: metrics.cpuPower)
                PowerBreakdownItem(label: "GPU", value: metrics.gpuPower)
                PowerBreakdownItem(label: "ANE", value: metrics.anePower)
            }
        }
    }

    private var memoryStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("Memory")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                // Memory pressure indicator
                Circle()
                    .fill(memoryPressureColor)
                    .frame(width: 6, height: 6)
                    .tooltip("Memory pressure: \(metrics.memoryPressure.rawValue)")
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", metrics.memoryUsagePercent))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(String(format: "%5.1f / %.0f GB", metrics.memoryUsedGB, metrics.memoryTotalGB))
                .font(.system(size: 9))
                .monospacedDigit()
                .foregroundColor(.secondary)
            if metrics.swapUsedGB > 0.01 {
                Text(String(format: "Swap %.1f GB", metrics.swapUsedGB))
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .foregroundColor(.orange)
                    .tooltip("Virtual memory on disk when RAM is full")
            }
        }
    }

    private var memoryPressureColor: Color {
        switch metrics.memoryPressure {
        case .nominal: return .green
        case .warn: return .yellow
        case .critical: return .red
        }
    }

    private var cpuStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("CPU")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .tooltip("E-cores: Efficiency (light tasks). P-cores: Performance (heavy work)")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", metrics.combinedCpuUsage))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(String(format: "E %3.0f%%", metrics.eCoreUsage))
                        .font(.system(size: 9))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    Text(String(format: "%3.1fG", metrics.eCoreFrequencyMHz / 1000))
                        .font(.system(size: 9))
                        .monospacedDigit()
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(metrics.eCoreFrequencyMHz > 0 ? 1 : 0)
                }
                .tooltip("Efficiency cores: power-saving, for light tasks")
                HStack(spacing: 4) {
                    Text(String(format: "P %3.0f%%", metrics.pCoreUsage))
                        .font(.system(size: 9))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    Text(String(format: "%3.1fG", metrics.pCoreFrequencyMHz / 1000))
                        .font(.system(size: 9))
                        .monospacedDigit()
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(metrics.pCoreFrequencyMHz > 0 ? 1 : 0)
                }
                .tooltip("Performance cores: high power, for demanding tasks")
            }
        }
    }

    private var gpuStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("GPU")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .tooltip("Integrated GPU usage. Video: 10-30%, Gaming/3D: 50-100%")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", metrics.gpuUsage))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if metrics.gpuFrequencyMHz > 0 {
                Text(String(format: "%.0f MHz", metrics.gpuFrequencyMHz))
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
    }

    private var batteryStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 10))
                    .foregroundColor(batteryColor)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("Battery")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if metrics.batteryIsCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }
            .tooltip("Battery level and charging status. Check power usage if draining fast.")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", metrics.batteryLevel))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let timeRemaining = metrics.batteryTimeRemaining {
                let hours = timeRemaining / 60
                let minutes = timeRemaining % 60
                Text(metrics.batteryIsCharging
                     ? String(format: "%d:%02d to full", hours, minutes)
                     : String(format: "%d:%02d remaining", hours, minutes))
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            } else {
                Text(batteryStatusText)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var batteryIcon: String {
        let level = metrics.batteryLevel
        if metrics.batteryIsCharging {
            return "battery.100.bolt"
        } else if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else if level > 10 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }

    private var batteryColor: Color {
        let level = metrics.batteryLevel
        if metrics.batteryIsCharging {
            return .green
        } else if level > 20 {
            return .green
        } else if level > 10 {
            return .yellow
        } else {
            return .red
        }
    }

    private var batteryStatusText: String {
        if metrics.batteryLevel >= 99 {
            return metrics.batteryIsCharging ? "Full" : "Full"
        } else if metrics.batteryIsCharging {
            return "Charging..."
        } else {
            return "Calculating..."
        }
    }

    private var networkStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                    .frame(width: Self.iconWidth, alignment: .center)
                Text("Network")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .tooltip("Current network throughput across all interfaces")
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(NetworkStats.formatCompact(metrics.networkBytesInPerSec))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(NetworkStats.formatCompactUnit(metrics.networkBytesInPerSec))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(NetworkStats.formatCompact(metrics.networkBytesOutPerSec))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(NetworkStats.formatCompactUnit(metrics.networkBytesOutPerSec))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Chart View with Fade

    private var chartView: some View {
        GeometryReader { _ in
            chartContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    /// Returns 0-1 indicating how "stressed" this metric is
    private var dangerLevel: Double {
        switch metric {
        case .memory:
            // Memory: concern starts at 75%, danger at 90%+
            let usage = metrics.memoryUsagePercent
            if usage < 75 { return 0 }
            return min(1, (usage - 75) / 25)
        case .cpu:
            // CPU: only concerned at very high sustained usage
            let usage = metrics.combinedCpuUsage
            if usage < 85 { return 0 }
            return min(1, (usage - 85) / 15)
        case .battery:
            // Battery: danger when LOW
            let level = metrics.batteryLevel
            if level > 25 { return 0 }
            return min(1, (25 - level) / 25)
        case .power:
            // Power: warm glow at high wattage (>35W)
            let power = metrics.packagePower
            if power < 35 { return 0 }
            return min(1, (power - 35) / 15) * 0.6 // reduced intensity
        case .gpu:
            // GPU: not really a concern
            return 0
        case .network:
            // Network: not a concern
            return 0
        }
    }

    private var dangerColor: Color {
        switch metric {
        case .battery:
            return .red
        case .memory:
            return .red
        case .cpu:
            return .orange
        case .power:
            return .orange
        case .gpu, .network:
            return .clear
        }
    }

    // Limit samples for chart performance (more points than pixels is wasteful)
    private var chartSamples: [Metrics] {
        let maxSamples = 30  // Reduced for better performance
        if samples.count <= maxSamples {
            return samples
        }
        return Array(samples.suffix(maxSamples))
    }

    @ViewBuilder
    private var chartContent: some View {
        let displaySamples = chartSamples
        if displaySamples.count > 1 {
            Chart {
                ForEach(displaySamples) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Value", ChartConfig.value(from: sample, for: metric))
                    )
                    .foregroundStyle(color.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: ChartConfig.chartDomain(for: metric))
            .chartBackground { _ in
                staticGridBackground
            }
            .drawingGroup()  // Flatten to Metal layer for better performance
        } else {
            // Placeholder when no data
            Rectangle()
                .fill(Color.clear)
        }
    }

    private var staticGridBackground: some View {
        Canvas { context, size in
            let gridColor = Color.primary.opacity(0.08)
            let horizontalLines = 3
            let verticalLines = 4

            // Horizontal lines
            for i in 1...horizontalLines {
                let y = size.height * CGFloat(i) / CGFloat(horizontalLines + 1)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // Vertical lines
            for i in 1...verticalLines {
                let x = size.width * CGFloat(i) / CGFloat(verticalLines + 1)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                PillToggle(
                    label: "Menu Bar",
                    isOn: settings.isShownInBar(metric),
                    color: color
                ) {
                    settings.setShownInBar(metric, !settings.isShownInBar(metric))
                }

                PillToggle(
                    label: "Panel",
                    isOn: settings.isModuleEnabled(metric),
                    color: color
                ) {
                    settings.setModuleEnabled(metric, !settings.isModuleEnabled(metric))
                    onSettingsChanged()
                }

                // Compact color dot button
                CompactColorPicker(color: settings.colorBinding(for: metric))
            }
        }
    }
}

// MARK: - Compact Color Picker with Swatch Grid

struct CompactColorPicker: View {
    @Binding var color: Color
    @State private var showPicker = false

    // Curated color palette that works well for metrics
    private static let colorSwatches: [[Color]] = [
        // Row 1: Vibrant primaries
        [.red, .orange, .yellow, .green, .mint, .cyan, .blue, .purple, .pink],
        // Row 2: Softer/muted variants
        [
            Color(hue: 0.0, saturation: 0.6, brightness: 0.85),   // Soft red
            Color(hue: 0.08, saturation: 0.7, brightness: 0.95),  // Soft orange
            Color(hue: 0.15, saturation: 0.5, brightness: 0.95),  // Soft yellow
            Color(hue: 0.35, saturation: 0.6, brightness: 0.75),  // Soft green
            Color(hue: 0.45, saturation: 0.5, brightness: 0.85),  // Soft mint
            Color(hue: 0.52, saturation: 0.6, brightness: 0.85),  // Soft cyan
            Color(hue: 0.6, saturation: 0.6, brightness: 0.85),   // Soft blue
            Color(hue: 0.75, saturation: 0.5, brightness: 0.85),  // Soft purple
            Color(hue: 0.92, saturation: 0.5, brightness: 0.9),   // Soft pink
        ]
    ]

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .onTapGesture { showPicker = true }
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                VStack(spacing: 6) {
                    ForEach(0..<Self.colorSwatches.count, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<Self.colorSwatches[row].count, id: \.self) { col in
                                let swatchColor = Self.colorSwatches[row][col]
                                Circle()
                                    .fill(swatchColor)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isColorSelected(swatchColor) ? Color.primary : Color.primary.opacity(0.1),
                                                lineWidth: isColorSelected(swatchColor) ? 2 : 1
                                            )
                                    )
                                    .scaleEffect(isColorSelected(swatchColor) ? 1.1 : 1.0)
                                    .onTapGesture {
                                        color = swatchColor
                                        showPicker = false
                                    }
                            }
                        }
                    }
                }
                .padding(10)
            }
            .help("Change color")
    }

    private func isColorSelected(_ swatch: Color) -> Bool {
        // Compare colors by converting to hex
        return swatch.toHex() == color.toHex()
    }
}

// MARK: - Power Breakdown Item

private struct PowerBreakdownItem: View {
    let label: String
    let value: Double

    var body: some View {
        Text("\(label) \(String(format: "%.1f", value))")
            .font(.system(size: 9).monospacedDigit())
            .foregroundColor(.secondary)
            .frame(width: 42, alignment: .leading)
    }
}

