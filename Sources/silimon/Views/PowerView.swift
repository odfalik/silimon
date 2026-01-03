import SwiftUI
import Charts

struct PowerView: View {
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory

    var body: some View {
        MetricCard(title: "Power", icon: "bolt.fill", color: .orange) {
            VStack(alignment: .leading, spacing: 6) {
                MetricValue(
                    value: String(format: "%.1f", metrics.packagePower),
                    unit: "W",
                    color: powerColor
                )

                // Power breakdown
                HStack(spacing: 8) {
                    powerItem("CPU", value: metrics.cpuPower)
                    powerItem("GPU", value: metrics.gpuPower)
                    if metrics.anePower > 0.01 {
                        powerItem("ANE", value: metrics.anePower)
                    }
                }

                // Sparkline
                if history.samples.count > 1 {
                    Chart {
                        ForEach(history.samples) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("Power", sample.packagePower)
                            )
                            .foregroundStyle(.orange.opacity(0.7))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 30)
                }
            }
        }
    }

    private func powerItem(_ label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.1fW", value))
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private var powerColor: Color {
        if metrics.packagePower > 30 {
            return .red
        } else if metrics.packagePower > 20 {
            return .orange
        }
        return .primary
    }
}
