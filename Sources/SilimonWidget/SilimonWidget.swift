// Note: This widget requires Xcode project configuration to work.
// To enable widgets, migrate this project to Xcode and add a Widget Extension target.
//
// The code below is ready to use once the widget target is configured.

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct SilimonEntry: TimelineEntry {
    let date: Date
    let power: Double
    let cpuUsage: Double
    let gpuUsage: Double
    let memoryUsage: Double
    let batteryLevel: Double
    let batteryCharging: Bool

    static var placeholder: SilimonEntry {
        SilimonEntry(
            date: Date(),
            power: 8.5,
            cpuUsage: 25,
            gpuUsage: 10,
            memoryUsage: 65,
            batteryLevel: 80,
            batteryCharging: false
        )
    }
}

// MARK: - Timeline Provider

struct SilimonTimelineProvider: TimelineProvider {
    typealias Entry = SilimonEntry

    func placeholder(in context: Context) -> SilimonEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SilimonEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SilimonEntry>) -> Void) {
        // Widgets refresh on a schedule set by the system
        // For real data, this would read from a shared app group container
        let entry = SilimonEntry.placeholder
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct SilimonWidgetEntryView: View {
    var entry: SilimonEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SilimonEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Spacer()
                Text(String(format: "%.1fW", entry.power))
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Divider()

            HStack(spacing: 12) {
                MetricPill(icon: "cpu.fill", value: entry.cpuUsage, unit: "%", color: .blue)
                MetricPill(icon: "memorychip", value: entry.memoryUsage, unit: "%", color: .purple)
            }

            if entry.batteryLevel > 0 {
                HStack {
                    Image(systemName: entry.batteryCharging ? "battery.100.bolt" : "battery.75")
                        .foregroundColor(entry.batteryLevel > 20 ? .green : .red)
                    Text("\(Int(entry.batteryLevel))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: SilimonEntry

    var body: some View {
        HStack(spacing: 16) {
            // Power section
            VStack(alignment: .leading, spacing: 4) {
                Label("Power", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", entry.power))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                + Text(" W")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // CPU & GPU
            VStack(alignment: .leading, spacing: 8) {
                MetricRow(icon: "cpu.fill", label: "CPU", value: entry.cpuUsage, color: .blue)
                MetricRow(icon: "cpu", label: "GPU", value: entry.gpuUsage, color: .green)
            }

            Divider()

            // Memory & Battery
            VStack(alignment: .leading, spacing: 8) {
                MetricRow(icon: "memorychip", label: "Memory", value: entry.memoryUsage, color: .purple)
                if entry.batteryLevel > 0 {
                    HStack {
                        Image(systemName: entry.batteryCharging ? "battery.100.bolt" : "battery.75")
                            .foregroundColor(entry.batteryLevel > 20 ? .green : .red)
                            .frame(width: 16)
                        Text("\(Int(entry.batteryLevel))%")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

struct MetricPill: View {
    let icon: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(Int(value))\(unit)")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            Text("\(Int(value))%")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Widget Configuration

// Uncomment when widget target is configured:
/*
@main
struct SilimonWidget: Widget {
    let kind: String = "SilimonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SilimonTimelineProvider()) { entry in
            SilimonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Silimon")
        .description("Monitor Apple Silicon performance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
*/
