import SwiftUI
import Charts

struct CPUView: View {
    let metrics: Metrics
    @ObservedObject var history: MetricsHistory

    var body: some View {
        MetricCard(title: "CPU", icon: "cpu.fill", color: .blue) {
            VStack(alignment: .leading, spacing: 6) {
                // E-cores and P-cores
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("E")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f%%", metrics.eCoreUsage))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("P")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f%%", metrics.pCoreUsage))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    if metrics.cpuPower > 0 {
                        Text(String(format: "%.1fW", metrics.cpuPower))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Combined usage bar
                MetricBar(value: metrics.combinedCpuUsage, color: .blue)

                // Frequencies
                HStack {
                    if metrics.eCoreFrequencyMHz > 0 {
                        Text(String(format: "E: %.0f MHz", metrics.eCoreFrequencyMHz))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if metrics.pCoreFrequencyMHz > 0 {
                        Text(String(format: "P: %.0f MHz", metrics.pCoreFrequencyMHz))
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
                                y: .value("Usage", sample.combinedCpuUsage)
                            )
                            .foregroundStyle(.blue.opacity(0.7))
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
}
