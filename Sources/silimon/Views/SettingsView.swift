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
                        Text("METRICS")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 1) {
                            MetricToggleRow(
                                icon: "bolt.fill",
                                title: "Power",
                                color: .orange,
                                showInBar: $settings.showPowerInStatusBar,
                                moduleEnabled: $settings.powerModuleEnabled,
                                onModuleChange: onSettingsChanged
                            )
                            MetricToggleRow(
                                icon: "memorychip",
                                title: "Memory",
                                color: .purple,
                                showInBar: $settings.showMemoryInStatusBar,
                                moduleEnabled: $settings.memoryModuleEnabled,
                                onModuleChange: onSettingsChanged
                            )
                            MetricToggleRow(
                                icon: "cpu.fill",
                                title: "CPU",
                                color: .blue,
                                showInBar: $settings.showCPUInStatusBar,
                                moduleEnabled: $settings.cpuModuleEnabled,
                                onModuleChange: onSettingsChanged
                            )
                            MetricToggleRow(
                                icon: "cpu",
                                title: "GPU",
                                color: .green,
                                showInBar: $settings.showGPUInStatusBar,
                                moduleEnabled: $settings.gpuModuleEnabled,
                                onModuleChange: onSettingsChanged
                            )
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
                                    Text("Issue")
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

struct MetricToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var showInBar: Bool
    @Binding var moduleEnabled: Bool
    var onModuleChange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon with color indicator
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            Text(title)
                .fontWeight(.medium)

            Spacer()

            // Menu bar toggle
            VStack(spacing: 2) {
                Toggle("", isOn: $showInBar)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: color))
                    .scaleEffect(0.8)
                Text("Bar")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            // Module toggle
            VStack(spacing: 2) {
                Toggle("", isOn: $moduleEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: color))
                    .scaleEffect(0.8)
                    .onChange(of: moduleEnabled) { _ in onModuleChange() }
                Text("Panel")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
