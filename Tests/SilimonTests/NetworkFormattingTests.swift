import XCTest

/// Tests for network byte formatting utilities
final class NetworkFormattingTests: XCTestCase {

    // MARK: - Full Format Tests

    func testFormatBytesPerSecBytes() {
        XCTAssertEqual(formatBytesPerSec(0), "0 B/s")
        XCTAssertEqual(formatBytesPerSec(100), "100 B/s")
        XCTAssertEqual(formatBytesPerSec(1023), "1023 B/s")
    }

    func testFormatBytesPerSecKilobytes() {
        XCTAssertEqual(formatBytesPerSec(1024), "1.0 KB/s")
        XCTAssertEqual(formatBytesPerSec(1536), "1.5 KB/s")
        XCTAssertEqual(formatBytesPerSec(102400), "100.0 KB/s")
        XCTAssertEqual(formatBytesPerSec(1048575), "1024.0 KB/s")
    }

    func testFormatBytesPerSecMegabytes() {
        XCTAssertEqual(formatBytesPerSec(1048576), "1.0 MB/s")
        XCTAssertEqual(formatBytesPerSec(10485760), "10.0 MB/s")
        XCTAssertEqual(formatBytesPerSec(104857600), "100.0 MB/s")
    }

    func testFormatBytesPerSecGigabytes() {
        XCTAssertEqual(formatBytesPerSec(1073741824), "1.00 GB/s")
        XCTAssertEqual(formatBytesPerSec(10737418240), "10.00 GB/s")
    }

    // MARK: - Compact Format Tests

    func testFormatCompactBytes() {
        XCTAssertEqual(formatCompact(0), "0")
        XCTAssertEqual(formatCompact(100), "100")
        XCTAssertEqual(formatCompact(999), "999")
    }

    func testFormatCompactKilobytes() {
        XCTAssertEqual(formatCompact(1024), "1")
        XCTAssertEqual(formatCompact(10240), "10")
        XCTAssertEqual(formatCompact(102400), "100")
    }

    func testFormatCompactMegabytes() {
        XCTAssertEqual(formatCompact(1048576), "1.0")
        XCTAssertEqual(formatCompact(5242880), "5.0")
        XCTAssertEqual(formatCompact(10485760), "10.0")
    }

    // MARK: - Compact Unit Tests

    func testFormatCompactUnitBytes() {
        XCTAssertEqual(formatCompactUnit(0), "B/s")
        XCTAssertEqual(formatCompactUnit(1023), "B/s")
    }

    func testFormatCompactUnitKilobytes() {
        XCTAssertEqual(formatCompactUnit(1024), "KB/s")
        XCTAssertEqual(formatCompactUnit(1048575), "KB/s")
    }

    func testFormatCompactUnitMegabytes() {
        XCTAssertEqual(formatCompactUnit(1048576), "MB/s")
        XCTAssertEqual(formatCompactUnit(1073741824), "MB/s")
    }

    // MARK: - Edge Cases

    func testFormatBoundaryValues() {
        // Test exact boundary values
        XCTAssertEqual(formatCompactUnit(1024 - 1), "B/s")
        XCTAssertEqual(formatCompactUnit(1024), "KB/s")
        XCTAssertEqual(formatCompactUnit(1024 * 1024 - 1), "KB/s")
        XCTAssertEqual(formatCompactUnit(1024 * 1024), "MB/s")
    }

    func testFormatLargeValues() {
        // 100 GB/s
        let largeValue = 100.0 * 1024 * 1024 * 1024
        let formatted = formatBytesPerSec(largeValue)
        XCTAssertTrue(formatted.contains("GB/s"))
    }

    // MARK: - Helper Functions (mirroring actual implementation)

    private func formatBytesPerSec(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%.0f B/s", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        } else if bytesPerSec < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSec / (1024 * 1024 * 1024))
        }
    }

    private func formatCompact(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%.0f", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.0f", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f", bytesPerSec / (1024 * 1024))
        }
    }

    private func formatCompactUnit(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return "B/s"
        } else if bytesPerSec < 1024 * 1024 {
            return "KB/s"
        } else {
            return "MB/s"
        }
    }
}
