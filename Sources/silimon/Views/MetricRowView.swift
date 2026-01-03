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
        }
    }

    var body: some View {
        HStack(spacing: 0) {
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
            HStack(spacing: 6) {
                Text(String(format: "CPU %.1f", metrics.cpuPower))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(String(format: "GPU %.1f", metrics.gpuPower))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
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
            HStack(spacing: 6) {
                Text(String(format: "E %.0f%%", metrics.eCoreUsage))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(String(format: "P %.0f%%", metrics.pCoreUsage))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
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
        }
    }

    private var chartDomain: ClosedRange<Double> {
        switch metric {
        case .power: return 0...50
        case .memory, .cpu, .gpu: return 0...100
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

