import SwiftUI

struct PopoverView: View {
    @ObservedObject var metricsCollector: MetricsCollector

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Silimon")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let error = metricsCollector.error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .help(error)
                }

                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Metrics Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    GPUView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
                    CPUView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
                    MemoryView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
                    PowerView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                if metricsCollector.currentMetrics.thermalPressure != .nominal {
                    Label(metricsCollector.currentMetrics.thermalPressure.rawValue.capitalized,
                          systemImage: "thermometer")
                        .foregroundColor(thermalColor)
                        .font(.caption)
                }

                Spacer()

                Text("Updated: \(timeString)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 420)
    }

    private var thermalColor: Color {
        switch metricsCollector.currentMetrics.thermalPressure {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .red
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: metricsCollector.currentMetrics.timestamp)
    }
}
