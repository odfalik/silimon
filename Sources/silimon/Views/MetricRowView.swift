import SwiftUI
import Charts

struct MetricRowView: View {
    let metric: MetricType
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory
    @ObservedObject var settings: Settings
    let isSettingsMode: Bool
    var onSettingsChanged: () -> Void

    private var color: Color {
        switch metric {
        case .power: return .orange
        case .memory: return .purple
        case .cpu: return .blue
        case .gpu: return .green
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
        .background(Color(NSColor.controlBackgroundColor))
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
                    .help("Memory pressure: \(metrics.memoryPressure.rawValue)")
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
                    .help("Virtual memory on disk when RAM is full")
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
                Text(metrics.batteryIsCharging ? "Charging..." : "Calculating...")
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

    // MARK: - Chart View with Fade

    private var chartView: some View {
        GeometryReader { geometry in
            chartContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        } else {
            // Placeholder when no data
            Rectangle()
                .fill(Color.clear)
        }
    }

    private func chartValue(for sample: Metrics) -> Double {
        switch metric {
        case .power: return sample.packagePower
        case .memory: return sample.memoryUsagePercent
        case .cpu: return sample.combinedCpuUsage
        case .gpu: return sample.gpuUsage
        case .battery: return sample.batteryLevel
        }
    }

    private var chartDomain: ClosedRange<Double> {
        switch metric {
        case .power: return 0...50
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

