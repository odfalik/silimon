import SwiftUI
import Charts

struct MetricRowView: View {
    let metric: MetricType
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory
    @ObservedObject var settings: Settings
    let isSettingsMode: Bool
    var onSettingsChanged: () -> Void

    @State private var pingScale: CGFloat = 0
    @State private var pingOpacity: Double = 0
    @State private var lastSampleCount: Int = 0

    private var color: Color {
        switch metric {
        case .power: return .orange
        case .memory: return .purple
        case .cpu: return .blue
        case .gpu: return .green
        case .network: return .cyan
        case .battery: return .green
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Drag handle (animates in/out)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: isSettingsMode ? 28 : 0, alignment: .leading)
                .opacity(isSettingsMode ? 1 : 0)
                .clipped()

            // Left side: stats
            statsView
                .frame(width: 100, alignment: .leading)

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
        .animation(.easeInOut(duration: 0.2), value: isSettingsMode)
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

    private var powerStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(color)
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
            HStack(spacing: 4) {
                Text(String(format: "CPU %.1f", metrics.cpuPower))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(String(format: "GPU %.1f", metrics.gpuPower))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                if metrics.anePower > 0.01 {
                    Text(String(format: "ANE %.1f", metrics.anePower))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var memoryStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                    .foregroundColor(color)
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
            Text(String(format: "%.1f / %.0f GB", metrics.memoryUsedGB, metrics.memoryTotalGB))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            if metrics.swapUsedGB > 0.01 {
                Text(String(format: "Swap %.1f GB", metrics.swapUsedGB))
                    .font(.system(size: 9))
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
                    Text(String(format: "E %.0f%%", metrics.eCoreUsage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    if metrics.eCoreFrequencyMHz > 0 {
                        Text(String(format: "%.1fG", metrics.eCoreFrequencyMHz / 1000))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .tooltip("Efficiency cores: power-saving, for light tasks")
                HStack(spacing: 4) {
                    Text(String(format: "P %.0f%%", metrics.pCoreUsage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    if metrics.pCoreFrequencyMHz > 0 {
                        Text(String(format: "%.1fG", metrics.pCoreFrequencyMHz / 1000))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
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
        GeometryReader { geometry in
            ZStack {
                chartContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .chartOverlay { proxy in
                        GeometryReader { overlayGeometry in
                            // Ping effect at the latest data point
                            if let lastSample = history.samples.last,
                               let xPos = proxy.position(forX: lastSample.timestamp),
                               let yPos = proxy.position(forY: chartValue(for: lastSample)) {
                                Circle()
                                    .fill(color.opacity(pingOpacity))
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(pingScale)
                                    .position(x: xPos, y: yPos)
                            }
                        }
                    }
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
            .onChange(of: history.samples.count) { newCount in
                if newCount > lastSampleCount {
                    triggerPing()
                }
                lastSampleCount = newCount
            }
        }
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

    private func triggerPing() {
        pingScale = 1.0
        pingOpacity = 0.5
        withAnimation(.easeOut(duration: 0.4)) {
            pingScale = 1.5
            pingOpacity = 0
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if history.samples.count > 1 {
            Chart {
                ForEach(history.samples) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Value", chartValue(for: sample))
                    )
                    .foregroundStyle(color.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: chartDomain)
            .chartBackground { proxy in
                TimelineView(.animation) { timeline in
                    GeometryReader { geometry in
                        gridBackground(in: geometry.size, at: timeline.date)
                    }
                }
            }
        } else {
            // Placeholder when no data
            Rectangle()
                .fill(Color.clear)
        }
    }

    private func gridBackground(in size: CGSize, at date: Date) -> some View {
        let horizontalLines = 3
        let columnInterval: TimeInterval = 15 // seconds
        let offset = date.timeIntervalSince1970.truncatingRemainder(dividingBy: columnInterval)
        let normalizedOffset = CGFloat(offset / columnInterval)

        return Canvas { context, canvasSize in
            let gridColor = Color.primary.opacity(0.08)

            // Horizontal lines (4 rows = 5 sections, so 4 internal lines)
            for i in 1...horizontalLines {
                let y = canvasSize.height * CGFloat(i) / CGFloat(horizontalLines + 1)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // Vertical lines sliding with time (5 second intervals over 60 seconds = 12 columns)
            let totalDuration: TimeInterval = 60
            let columnCount = Int(totalDuration / columnInterval)
            let columnWidth = canvasSize.width / CGFloat(columnCount)

            for i in 0...columnCount {
                let baseX = canvasSize.width - CGFloat(i) * columnWidth
                let x = baseX + normalizedOffset * columnWidth
                if x >= 0 && x <= canvasSize.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                    context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
                }
            }
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.15),
                    .init(color: .black, location: 0.85),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func chartValue(for sample: Metrics) -> Double {
        switch metric {
        case .power: return sample.packagePower
        case .memory: return sample.memoryUsagePercent
        case .cpu: return sample.combinedCpuUsage
        case .gpu: return sample.gpuUsage
        case .network: return sample.networkBytesInPerSec / 1024 / 1024 // MB/s
        case .battery: return sample.batteryLevel
        }
    }

    private var chartDomain: ClosedRange<Double> {
        switch metric {
        case .power: return 0...50
        case .network: return 0...10 // 0-10 MB/s
        case .memory, .cpu, .gpu, .battery: return 0...100
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
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
            }
        }
    }
}

