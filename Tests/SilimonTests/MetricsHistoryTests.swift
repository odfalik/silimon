import XCTest

/// Tests for MetricsHistory circular buffer behavior
final class MetricsHistoryTests: XCTestCase {

    // MARK: - Basic Functionality

    func testEmptyHistoryReturnsEmptyMetrics() {
        let history = TestMetricsHistory()
        XCTAssertTrue(history.samples.isEmpty)
        XCTAssertNotNil(history.latest)
    }

    func testAddSingleSample() {
        let history = TestMetricsHistory()
        let sample = TestMetrics(timestamp: Date(), packagePower: 10.5)

        history.add(sample)

        XCTAssertEqual(history.samples.count, 1)
        XCTAssertEqual(history.latest.packagePower, 10.5)
    }

    func testAddMultipleSamples() {
        let history = TestMetricsHistory()

        for i in 1...5 {
            let sample = TestMetrics(timestamp: Date(), packagePower: Double(i))
            history.add(sample)
        }

        XCTAssertEqual(history.samples.count, 5)
        XCTAssertEqual(history.latest.packagePower, 5.0)
    }

    // MARK: - Circular Buffer Trimming

    func testTrimsOldSamples() {
        let history = TestMetricsHistory(maxDuration: 5.0)  // 5 second window

        // Add a sample from 10 seconds ago
        let oldSample = TestMetrics(timestamp: Date().addingTimeInterval(-10), packagePower: 1.0)
        history.add(oldSample)

        // Add a recent sample
        let newSample = TestMetrics(timestamp: Date(), packagePower: 2.0)
        history.add(newSample)

        // Old sample should be trimmed
        XCTAssertEqual(history.samples.count, 1)
        XCTAssertEqual(history.latest.packagePower, 2.0)
    }

    func testKeepsSamplesWithinWindow() {
        let history = TestMetricsHistory(maxDuration: 60.0)  // 60 second window
        let baseTime = Date()

        // Add samples within the window
        for i in 0..<10 {
            let sample = TestMetrics(
                timestamp: baseTime.addingTimeInterval(-Double(i) * 5),  // Every 5 seconds
                packagePower: Double(i)
            )
            history.add(sample)
        }

        // All should be kept (50 seconds total, within 60 second window)
        XCTAssertEqual(history.samples.count, 10)
    }

    func testMixedOldAndNewSamples() {
        let history = TestMetricsHistory(maxDuration: 30.0)  // 30 second window
        let baseTime = Date()

        // Add some old samples (> 30 seconds ago)
        for i in 0..<3 {
            let sample = TestMetrics(
                timestamp: baseTime.addingTimeInterval(-60 - Double(i)),
                packagePower: Double(i)
            )
            history.add(sample)
        }

        // Add some new samples (within window)
        for i in 0..<5 {
            let sample = TestMetrics(
                timestamp: baseTime.addingTimeInterval(-Double(i) * 5),
                packagePower: Double(100 + i)
            )
            history.add(sample)
        }

        // Only new samples should remain
        XCTAssertEqual(history.samples.count, 5)
        XCTAssertTrue(history.samples.allSatisfy { $0.packagePower >= 100 })
    }

    // MARK: - Chart Data Generation

    func testPowerDataGeneration() {
        let history = TestMetricsHistory()
        let baseTime = Date()

        history.add(TestMetrics(timestamp: baseTime, packagePower: 10.0))
        history.add(TestMetrics(timestamp: baseTime.addingTimeInterval(1), packagePower: 15.0))
        history.add(TestMetrics(timestamp: baseTime.addingTimeInterval(2), packagePower: 20.0))

        let powerData = history.powerData()

        XCTAssertEqual(powerData.count, 3)
        XCTAssertEqual(powerData[0].1, 10.0)
        XCTAssertEqual(powerData[1].1, 15.0)
        XCTAssertEqual(powerData[2].1, 20.0)
    }

    func testCpuUsageDataGeneration() {
        let history = TestMetricsHistory()
        let baseTime = Date()

        history.add(TestMetrics(timestamp: baseTime, eCoreUsage: 30, pCoreUsage: 60))
        history.add(TestMetrics(timestamp: baseTime.addingTimeInterval(1), eCoreUsage: 40, pCoreUsage: 80))

        let cpuData = history.cpuUsageData()

        XCTAssertEqual(cpuData.count, 2)
        // Combined usage = (eCoreUsage + pCoreUsage * 2) / 3
        XCTAssertEqual(cpuData[0].1, 50.0, accuracy: 0.1)  // (30 + 60*2) / 3 = 50
        XCTAssertEqual(cpuData[1].1, 66.67, accuracy: 0.1)  // (40 + 80*2) / 3 = 66.67
    }

    func testMemoryUsageDataGeneration() {
        let history = TestMetricsHistory()
        let baseTime = Date()

        history.add(TestMetrics(timestamp: baseTime, memoryUsedGB: 8, memoryTotalGB: 16))
        history.add(TestMetrics(timestamp: baseTime.addingTimeInterval(1), memoryUsedGB: 12, memoryTotalGB: 16))

        let memData = history.memoryUsageData()

        XCTAssertEqual(memData.count, 2)
        XCTAssertEqual(memData[0].1, 50.0)  // 8/16 * 100
        XCTAssertEqual(memData[1].1, 75.0)  // 12/16 * 100
    }

    // MARK: - Test Helpers

    struct TestMetrics {
        let timestamp: Date
        var packagePower: Double = 0
        var eCoreUsage: Double = 0
        var pCoreUsage: Double = 0
        var memoryUsedGB: Double = 0
        var memoryTotalGB: Double = 0
        var gpuUsage: Double = 0

        var combinedCpuUsage: Double {
            (eCoreUsage + pCoreUsage * 2) / 3
        }

        var memoryUsagePercent: Double {
            guard memoryTotalGB > 0 else { return 0 }
            return (memoryUsedGB / memoryTotalGB) * 100
        }

        static var empty: TestMetrics {
            TestMetrics(timestamp: Date())
        }
    }

    class TestMetricsHistory {
        private(set) var samples: [TestMetrics] = []
        private let maxDuration: TimeInterval

        init(maxDuration: TimeInterval = 60) {
            self.maxDuration = maxDuration
        }

        func add(_ metrics: TestMetrics) {
            samples.append(metrics)
            trimOldSamples()
        }

        private func trimOldSamples() {
            let cutoff = Date().addingTimeInterval(-maxDuration)
            samples.removeAll { $0.timestamp < cutoff }
        }

        var latest: TestMetrics {
            samples.last ?? .empty
        }

        func powerData() -> [(Date, Double)] {
            samples.map { ($0.timestamp, $0.packagePower) }
        }

        func cpuUsageData() -> [(Date, Double)] {
            samples.map { ($0.timestamp, $0.combinedCpuUsage) }
        }

        func memoryUsageData() -> [(Date, Double)] {
            samples.map { ($0.timestamp, $0.memoryUsagePercent) }
        }

        func gpuUsageData() -> [(Date, Double)] {
            samples.map { ($0.timestamp, $0.gpuUsage) }
        }
    }
}
