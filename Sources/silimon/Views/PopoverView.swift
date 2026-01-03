import SwiftUI

struct PopoverView: View {
    @ObservedObject var metricsCollector: MetricsCollector
    @ObservedObject var settings: Settings
    @State private var showSettings = false
    var onSettingsChanged: () -> Void

    var body: some View {
        if showSettings {
            SettingsView(
                settings: settings,
                showSettings: $showSettings,
                onSettingsChanged: onSettingsChanged
            )
        } else {
            mainView
        }
    }

    private var mainView: some View {
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

                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Metrics Grid - ordered by settings.metricOrder
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(settings.metricOrder) { metric in
                        if settings.isModuleEnabled(metric) {
                            metricView(for: metric)
                        }
                    }
                }
                .padding()
            }

            // Footer - only show if thermal pressure is not nominal
            if metricsCollector.currentMetrics.thermalPressure != .nominal {
                Divider()

                HStack {
                    Label(metricsCollector.currentMetrics.thermalPressure.rawValue.capitalized,
                          systemImage: "thermometer")
                        .foregroundColor(thermalColor)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 320, height: 420)
    }

    @ViewBuilder
    private func metricView(for metric: MetricType) -> some View {
        switch metric {
        case .power:
            PowerView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
        case .memory:
            MemoryView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
        case .cpu:
            CPUView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
        case .gpu:
            GPUView(metrics: metricsCollector.currentMetrics, history: metricsCollector.history)
        }
    }

    private var thermalColor: Color {
        switch metricsCollector.currentMetrics.thermalPressure {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .red
        }
    }
}
