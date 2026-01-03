import SwiftUI
import UniformTypeIdentifiers

struct PopoverView: View {
    @ObservedObject var metricsCollector: MetricsCollector
    @ObservedObject var settings: Settings
    @ObservedObject var updateChecker: UpdateChecker
    @State private var isSettingsMode = false
    @State private var draggedMetric: MetricType?
    var onSettingsChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Update banner at top when available (only in settings mode)
            if updateChecker.updateAvailable && isSettingsMode {
                updateBanner
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // Star repo prompt (shown once after using for a while)
            if settings.shouldShowStarPrompt && !isSettingsMode {
                starPromptBanner
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

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

            if isSettingsMode {
                Text("v\(version)")
                    .font(.subheadline)
                    .fontWeight(.light)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let error = metricsCollector.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .help(error)
            }

            Button(action: { isSettingsMode.toggle() }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSettingsMode ? "xmark" : "gearshape.fill")
                        .foregroundColor(isSettingsMode ? .primary : .secondary)

                    if updateChecker.updateAvailable && !isSettingsMode {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
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
                    if metricsCollector.isLowPowerMode {
                        Text(String(format: "%.1fs", metricsCollector.effectiveSamplingInterval))
                            .font(.caption)
                            .foregroundColor(.green)
                            .monospacedDigit()
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text(String(format: "%.1fs", settings.samplingInterval))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }

                Slider(value: $settings.samplingInterval, in: 0.5...5.0, step: 0.5)
                    .onChange(of: settings.samplingInterval) { _ in onSettingsChanged() }

                if metricsCollector.isLowPowerMode {
                    Text("Reduced for Low Power Mode")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
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

    // MARK: - Star Prompt Banner

    private var starPromptBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enjoying Silimon?")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("A star on GitHub helps others discover it!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button(action: {
                    settings.hasAskedToStarRepo = true
                }) {
                    Text("Not now")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    settings.hasAskedToStarRepo = true
                    if let url = URL(string: "https://github.com/odfalik/silimon") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star")
                            .font(.caption)
                        Text("Star on GitHub")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Update Banner

    private var updateBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available: v\(updateChecker.latestVersion ?? "")")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Run `brew upgrade silimon` in your terminal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button(action: {
                    // Copy command to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("brew upgrade silimon", forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("Copy")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                if let url = updateChecker.releaseURL {
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text("Release Notes")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
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
