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
                VStack(alignment: .leading, spacing: 16) {
                    // Status Bar Section
                    SettingsSection(title: "Status Bar Display") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Show in menu bar:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Toggle("Power (W)", isOn: $settings.showPowerInStatusBar)
                            Toggle("Memory (GB)", isOn: $settings.showMemoryInStatusBar)
                            Toggle("CPU (%)", isOn: $settings.showCPUInStatusBar)
                            Toggle("GPU (%)", isOn: $settings.showGPUInStatusBar)
                        }
                    }

                    // Modules Section
                    SettingsSection(title: "Modules") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enable/disable monitoring modules:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Toggle("GPU", isOn: $settings.gpuModuleEnabled)
                                .onChange(of: settings.gpuModuleEnabled) { _ in onSettingsChanged() }
                            Toggle("CPU", isOn: $settings.cpuModuleEnabled)
                                .onChange(of: settings.cpuModuleEnabled) { _ in onSettingsChanged() }
                            Toggle("Memory", isOn: $settings.memoryModuleEnabled)
                                .onChange(of: settings.memoryModuleEnabled) { _ in onSettingsChanged() }
                            Toggle("Power", isOn: $settings.powerModuleEnabled)
                                .onChange(of: settings.powerModuleEnabled) { _ in onSettingsChanged() }
                        }
                    }

                    // Sampling Rate Section
                    SettingsSection(title: "Sampling Rate") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Interval:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1fs", settings.samplingInterval))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(value: $settings.samplingInterval, in: 0.5...5.0, step: 0.5)
                                .onChange(of: settings.samplingInterval) { _ in onSettingsChanged() }

                            HStack {
                                Text("0.5s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .opacity(0.7)
                                Spacer()
                                Text("5.0s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .opacity(0.7)
                            }
                        }
                    }

                    // Startup Section
                    SettingsSection(title: "Startup") {
                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    }

                    Spacer(minLength: 16)

                    // Quit Button
                    Button(action: { NSApp.terminate(nil) }) {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit Silimon")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
        }
        .frame(width: 320, height: 420)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            content
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
