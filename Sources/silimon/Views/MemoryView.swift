import SwiftUI
import Charts

struct MemoryView: View {
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory

    var body: some View {
        MetricCard(title: "Memory", icon: "memorychip", color: .green) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    MetricValue(
                        value: String(format: "%.1f", metrics.memoryUsedGB),
                        unit: "GB",
                        color: usageColor
                    )

                    Spacer()

                    Text(String(format: "/ %.0f GB", metrics.memoryTotalGB))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                MetricBar(value: metrics.memoryUsagePercent, color: barColor)

                HStack {
                    // Memory pressure indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pressureColor)
                            .frame(width: 6, height: 6)
                        Text(metrics.memoryPressure.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Swap if active
                    if metrics.swapUsedGB > 0.01 {
                        Text(String(format: "Swap: %.1f GB", metrics.swapUsedGB))
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                // Sparkline
                if history.samples.count > 1 {
                    Chart {
                        ForEach(history.samples) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("Usage", sample.memoryUsagePercent)
                            )
                            .foregroundStyle(.green.opacity(0.7))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...100)
                    .frame(height: 30)
                }
            }
        }
    }

    private var usageColor: Color {
        if metrics.memoryUsagePercent > 90 {
            return .red
        } else if metrics.memoryUsagePercent > 75 {
            return .orange
        }
        return .primary
    }

    private var barColor: Color {
        switch metrics.memoryPressure {
        case .critical: return .red
        case .warn: return .orange
        case .nominal: return .green
        }
    }

    private var pressureColor: Color {
        switch metrics.memoryPressure {
        case .critical: return .red
        case .warn: return .yellow
        case .nominal: return .green
        }
    }
}
