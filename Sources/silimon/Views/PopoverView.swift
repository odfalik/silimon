import SwiftUI
import UniformTypeIdentifiers

struct PopoverView: View {
    @ObservedObject var metricsCollector: MetricsCollector
    @ObservedObject var settings: Settings
    @State private var isSettingsMode = false
    @State private var draggedMetric: MetricType?
    var onSettingsChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Metric rows
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(settings.metricOrder) { metric in
                        if settings.isModuleEnabled(metric) || isSettingsMode {
                            MetricRowView(
                                metric: metric,
                                metrics: metricsCollector.currentMetrics,
                                history: metricsCollector.history,
                                settings: settings,
                                isSettingsMode: isSettingsMode,
                                onSettingsChanged: onSettingsChanged
                            )
                            .opacity(draggedMetric == metric ? 0.5 : (settings.isModuleEnabled(metric) ? 1.0 : 0.5))
                            .onDrag(isSettingsMode ? {
                                draggedMetric = metric
                                return NSItemProvider(object: metric.rawValue as NSString)
                            } : {
                                return NSItemProvider()
                            })
                            .onDrop(of: [.text], delegate: MetricDropDelegate(
                                metric: metric,
                                metrics: $settings.metricOrder,
                                draggedMetric: $draggedMetric
                            ))
                        }
                    }

                    // Settings controls (only in settings mode)
                    if isSettingsMode {
                        settingsControls
                    }
                }
                .padding()
            }

            // Thermal warning footer (only when not nominal)
            if metricsCollector.currentMetrics.thermalPressure != .nominal {
                Divider()
                thermalWarning
            }
        }
        .frame(width: 320, height: 400)
    }

    // MARK: - Header

    private var headerView: some View {
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

            Button(action: { isSettingsMode.toggle() }) {
                Image(systemName: isSettingsMode ? "xmark" : "gearshape.fill")
                    .foregroundColor(isSettingsMode ? .primary : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Settings Controls

    private var settingsControls: some View {
        VStack(spacing: 12) {
            // Refresh rate
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text("Refresh rate")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1fs", settings.samplingInterval))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $settings.samplingInterval, in: 0.5...5.0, step: 0.5)
                    .onChange(of: settings.samplingInterval) { _ in onSettingsChanged() }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            // Launch at login
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text("Launch at login")
                    .font(.caption)
                Spacer()
                Toggle("", isOn: $settings.launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .scaleEffect(0.8)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    if let url = URL(string: "https://github.com/odfalik/silimon") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star")
                            .font(.caption)
                        Text("Star")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    if let url = URL(string: "https://github.com/odfalik/silimon/issues/new") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.bubble")
                            .font(.caption)
                        Text("Issue")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Button(action: { NSApp.terminate(nil) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                        Text("Quit")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Thermal Warning

    private var thermalWarning: some View {
        HStack {
            Label(
                metricsCollector.currentMetrics.thermalPressure.rawValue.capitalized,
                systemImage: "thermometer"
            )
            .foregroundColor(thermalColor)
            .font(.caption)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var thermalColor: Color {
        switch metricsCollector.currentMetrics.thermalPressure {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .red
        }
    }
}

// MARK: - Drop Delegate

struct MetricDropDelegate: DropDelegate {
    let metric: MetricType
    @Binding var metrics: [MetricType]
    @Binding var draggedMetric: MetricType?

    func performDrop(info: DropInfo) -> Bool {
        draggedMetric = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedMetric = draggedMetric,
              draggedMetric != metric,
              let fromIndex = metrics.firstIndex(of: draggedMetric),
              let toIndex = metrics.firstIndex(of: metric) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            metrics.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
