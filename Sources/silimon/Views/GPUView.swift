import SwiftUI
import Charts

struct GPUView: View {
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory

    var body: some View {
        MetricCard(title: "GPU", icon: "cpu", color: .purple) {
            VStack(alignment: .leading, spacing: 6) {
                MetricValue(
                    value: String(format: "%.0f", metrics.gpuUsage),
                    unit: "%",
                    color: usageColor
                )

                MetricBar(value: metrics.gpuUsage, color: .purple)

                HStack {
                    if metrics.gpuFrequencyMHz > 0 {
                        Text(String(format: "%.0f MHz", metrics.gpuFrequencyMHz))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if metrics.gpuPower > 0 {
                        Text(String(format: "%.1fW", metrics.gpuPower))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Sparkline
                if history.samples.count > 1 {
                    Chart {
                        ForEach(history.samples) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("Usage", sample.gpuUsage)
                            )
                            .foregroundStyle(.purple.opacity(0.7))
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
        if metrics.gpuUsage > 90 {
            return .red
        } else if metrics.gpuUsage > 70 {
            return .orange
        }
        return .primary
    }
}
