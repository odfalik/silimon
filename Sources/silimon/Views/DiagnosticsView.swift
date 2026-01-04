import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var updateChecker: UpdateChecker
    @State private var report: DiagnosticReport?
    @State private var isRunning = false
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("System Diagnostics")
                    .font(.headline)
                Spacer()
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if let report = report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // System info
                        systemInfoSection(report.systemInfo)

                        // Checks
                        checksSection(report.checks)

                        // Summary
                        summarySection(report)

                        // Action buttons
                        HStack(spacing: 8) {
                            Button(action: { copyReport(report) }) {
                                HStack {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "Copied!" : "Copy Report")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(copied)

                            Button(action: { updateChecker.checkForUpdates() }) {
                                HStack {
                                    if updateChecker.isChecking {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text("Check Updates")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(updateChecker.isChecking)
                        }

                        // Update status
                        if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Update available: v\(version)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                ProgressView("Running diagnostics...")
                Spacer()
            }
        }
        .frame(width: 320, height: 400)
        .onAppear {
            runDiagnostics()
        }
    }

    // MARK: - Sections

    private func systemInfoSection(_ info: SystemInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("System")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                infoRow("macOS", info.macOSVersion)
                infoRow("Architecture", info.architecture)
                infoRow("Chip", info.chipModel)
                infoRow("Silimon", "v\(info.silimonVersion)")
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func checksSection(_ checks: [DiagnosticResult]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Checks")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(spacing: 2) {
                ForEach(Array(checks.enumerated()), id: \.offset) { _, check in
                    checkRow(check)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func summarySection(_ report: DiagnosticReport) -> some View {
        HStack(spacing: 8) {
            if report.hasFailures {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Some checks failed")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if report.hasWarnings {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Some warnings detected")
                    .font(.caption)
                    .foregroundColor(.yellow)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("All checks passed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Spacer()
        }
        .padding(10)
        .background(
            report.hasFailures ? Color.red.opacity(0.1) :
            report.hasWarnings ? Color.yellow.opacity(0.1) :
            Color.green.opacity(0.1)
        )
        .cornerRadius(8)
    }

    // MARK: - Rows

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func checkRow(_ check: DiagnosticResult) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                statusIcon(check.status)
                Text(check.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(check.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if let suggestion = check.suggestion {
                Text(suggestion)
                    .font(.caption2)
                    .foregroundColor(check.status == .fail ? .red : .yellow)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusIcon(_ status: DiagnosticStatus) -> some View {
        Group {
            switch status {
            case .pass:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
            case .fail:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.caption)
    }

    // MARK: - Actions

    private func runDiagnostics() {
        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = DiagnosticService.shared.runDiagnostics()
            DispatchQueue.main.async {
                self.report = result
                self.isRunning = false
            }
        }
    }

    private func copyReport(_ report: DiagnosticReport) {
        let text = DiagnosticService.shared.formatReportForCLI(report)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}
