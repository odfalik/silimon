import XCTest

/// Tests for parsing logic used in metrics collection
final class ParsingTests: XCTestCase {

    // MARK: - vm_stat Parsing Tests

    func testParseVmStatExtractsPages() {
        let vmStatOutput = """
        Mach Virtual Memory Statistics: (page size of 16384 bytes)
        Pages free:                               12345.
        Pages active:                            543210.
        Pages inactive:                          123456.
        Pages speculative:                        12345.
        Pages throttled:                              0.
        Pages wired down:                        234567.
        Pages purgeable:                          12345.
        "Translation faults":                1234567890.
        Pages copy-on-write:                  12345678.
        Pages zero filled:                   123456789.
        Pages reactivated:                     1234567.
        Pages purged:                           123456.
        File-backed pages:                      234567.
        Anonymous pages:                        345678.
        Pages stored in compressor:             456789.
        Pages occupied by compressor:           123456.
        """

        let pages = extractPages(from: "Pages wired down:                        234567.", label: "Pages wired down:")
        XCTAssertEqual(pages, 234567)

        let activePages = extractPages(from: "Pages active:                            543210.", label: "Pages active:")
        XCTAssertEqual(activePages, 543210)

        let compressorPages = extractPages(from: "Pages occupied by compressor:           123456.", label: "Pages occupied by compressor:")
        XCTAssertEqual(compressorPages, 123456)
    }

    func testParseVmStatHandlesMissingValue() {
        let pages = extractPages(from: "Pages wired down:", label: "Pages wired down:")
        XCTAssertEqual(pages, 0)
    }

    func testParseVmStatHandlesInvalidFormat() {
        let pages = extractPages(from: "Invalid line without colon", label: "Invalid line without colon")
        XCTAssertEqual(pages, 0)
    }

    func testVmStatMemoryCalculation() {
        let pageSize: Double = 16384  // Apple Silicon uses 16KB pages
        let wired: Double = 100000
        let active: Double = 200000
        let compressed: Double = 50000

        let usedBytes = (wired + active + compressed) * pageSize
        let usedGB = usedBytes / 1_073_741_824

        // 350000 pages * 16384 bytes = 5,734,400,000 bytes = ~5.34 GB
        XCTAssertEqual(usedGB, 5.34027, accuracy: 0.001)
    }

    // MARK: - Swap Usage Parsing Tests

    func testParseSwapUsage() {
        let swapOutput = "vm.swapusage: total = 2048.00M  used = 256.50M  free = 1791.50M"
        let usedGB = parseSwapUsage(swapOutput)
        XCTAssertEqual(usedGB, 0.2505, accuracy: 0.001)
    }

    func testParseSwapUsageZero() {
        let swapOutput = "vm.swapusage: total = 2048.00M  used = 0.00M  free = 2048.00M"
        let usedGB = parseSwapUsage(swapOutput)
        XCTAssertEqual(usedGB, 0.0, accuracy: 0.001)
    }

    func testParseSwapUsageInvalidFormat() {
        let swapOutput = "Invalid output"
        let usedGB = parseSwapUsage(swapOutput)
        XCTAssertEqual(usedGB, 0.0)
    }

    // MARK: - Memory Pressure Parsing Tests

    func testParseMemoryPressureNominal() {
        let output = "System-wide memory free percentage: 75%\nThe system is at a nominal memory pressure level."
        let pressure = parseMemoryPressure(output)
        XCTAssertEqual(pressure, "nominal")
    }

    func testParseMemoryPressureWarn() {
        let output = "System-wide memory free percentage: 25%\nThe system is at a warn memory pressure level."
        let pressure = parseMemoryPressure(output)
        XCTAssertEqual(pressure, "warn")
    }

    func testParseMemoryPressureCritical() {
        let output = "System-wide memory free percentage: 5%\nThe system is at a critical memory pressure level."
        let pressure = parseMemoryPressure(output)
        XCTAssertEqual(pressure, "critical")
    }

    // MARK: - Helper Functions (mirroring actual implementation)

    private func extractPages(from line: String, label: String) -> Double {
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return 0 }

        let valueStr = components[1]
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")

        return Double(valueStr) ?? 0
    }

    private func parseSwapUsage(_ output: String) -> Double {
        if let usedRange = output.range(of: "used = ") {
            let afterUsed = output[usedRange.upperBound...]
            if let endRange = afterUsed.range(of: "M") {
                let valueStr = String(afterUsed[..<endRange.lowerBound])
                if let valueMB = Double(valueStr.trimmingCharacters(in: .whitespaces)) {
                    return valueMB / 1024  // MB to GB
                }
            }
        }
        return 0
    }

    private func parseMemoryPressure(_ output: String) -> String {
        if output.contains("critical") {
            return "critical"
        } else if output.contains("warn") {
            return "warn"
        } else {
            return "nominal"
        }
    }
}
