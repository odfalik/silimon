import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Binding var showSettings: Bool
    var onSettingsChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { showSettings = false }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Metrics Section
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("METRICS")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Drag to reorder")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(settings.metricOrder) { metric in
                                MetricRow(
                                    metric: metric,
                                    settings: settings,
                                    onModuleChange: onSettingsChanged
                                )
                                if metric != settings.metricOrder.last {
                                    Divider().padding(.leading, 52)
                                }
                            }
                            .onMove { from, to in
                                settings.metricOrder.move(fromOffsets: from, toOffset: to)
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Sampling Rate Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REFRESH RATE")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Update interval")
                                Spacer()
                                Text(String(format: "%.1fs", settings.samplingInterval))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(value: $settings.samplingInterval, in: 0.5...5.0, step: 0.5)
                                .onChange(of: settings.samplingInterval) { _ in onSettingsChanged() }

                            HStack {
                                Text("Faster")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Battery saver")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Startup Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STARTUP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        HStack {
                            Image(systemName: "power")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Launch at login")
                            Spacer()
                            Toggle("", isOn: $settings.launchAtLogin)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    Spacer(minLength: 8)

                    // Footer buttons
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: {
                                if let url = URL(string: "https://github.com/odfalik/silimon") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "star")
                                    Text("Star")
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
                                HStack {
                                    Image(systemName: "exclamationmark.bubble")
                                    Text("Report Issue")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button(action: { NSApp.terminate(nil) }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Quit Silimon")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 420)
    }
}

// MARK: - Metric Row with Pill Toggles

struct MetricRow: View {
    let metric: MetricType
    @ObservedObject var settings: Settings
    var onModuleChange: () -> Void

    private var color: Color {
        switch metric {
        case .power: return .orange
        case .memory: return .purple
        case .cpu: return .blue
        case .gpu: return .green
        }
    }

    private var showInBar: Bool {
        settings.isShownInBar(metric)
    }

    private var moduleEnabled: Bool {
        settings.isModuleEnabled(metric)
    }

    private var isDisabled: Bool {
        !showInBar && !moduleEnabled
    }

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))

            // Icon with color indicator
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(isDisabled ? 0.05 : 0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: metric.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isDisabled ? .secondary : color)
            }

            Text(metric.displayName)
                .fontWeight(.medium)
                .foregroundColor(isDisabled ? .secondary : .primary)

            Spacer()

            // Pill toggles
            HStack(spacing: 6) {
                PillToggle(
                    label: "Bar",
                    isOn: showInBar,
                    color: color
                ) {
                    settings.setShownInBar(metric, !showInBar)
                }

                PillToggle(
                    label: "Panel",
                    isOn: moduleEnabled,
                    color: color
                ) {
                    settings.setModuleEnabled(metric, !moduleEnabled)
                    onModuleChange()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Pill Toggle Button

struct PillToggle: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isOn ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? color : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isOn ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
