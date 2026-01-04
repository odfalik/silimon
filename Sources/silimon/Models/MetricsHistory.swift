import Foundation

/// Circular buffer for storing metrics history
class MetricsHistory: ObservableObject {
    @Published private(set) var samples: [Metrics] = []
    var maxDuration: TimeInterval {
        didSet {
            trimOldSamples()
        }
    }

    init(maxDuration: TimeInterval = 60) {
        self.maxDuration = maxDuration
    }

    func add(_ metrics: Metrics) {
        samples.append(metrics)
        trimOldSamples()
    }

    private func trimOldSamples() {
        let cutoff = Date().addingTimeInterval(-maxDuration)
        samples.removeAll { $0.timestamp < cutoff }
    }

    var latest: Metrics {
        samples.last ?? .empty
    }

    // Helper for chart data
    func gpuUsageData() -> [(Date, Double)] {
        samples.map { ($0.timestamp, $0.gpuUsage) }
    }

    func cpuUsageData() -> [(Date, Double)] {
        samples.map { ($0.timestamp, $0.combinedCpuUsage) }
    }

    func memoryUsageData() -> [(Date, Double)] {
        samples.map { ($0.timestamp, $0.memoryUsagePercent) }
    }

    func powerData() -> [(Date, Double)] {
        samples.map { ($0.timestamp, $0.packagePower) }
    }
}
