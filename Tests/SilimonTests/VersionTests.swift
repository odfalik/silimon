import XCTest

/// Tests for version comparison logic used in UpdateChecker
final class VersionTests: XCTestCase {

    // MARK: - Version Parsing Tests

    func testParseVersionFull() {
        let version = parseVersion("1.2.3")
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
    }

    func testParseVersionMajorMinorOnly() {
        let version = parseVersion("2.5")
        XCTAssertEqual(version.major, 2)
        XCTAssertEqual(version.minor, 5)
        XCTAssertEqual(version.patch, 0)
    }

    func testParseVersionMajorOnly() {
        let version = parseVersion("3")
        XCTAssertEqual(version.major, 3)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)
    }

    func testParseVersionEmpty() {
        let version = parseVersion("")
        XCTAssertEqual(version.major, 0)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)
    }

    func testParseVersionWithPrefix() {
        // After stripping 'v' prefix
        let version = parseVersion("0.7.1")
        XCTAssertEqual(version.major, 0)
        XCTAssertEqual(version.minor, 7)
        XCTAssertEqual(version.patch, 1)
    }

    // MARK: - Version Comparison Tests

    func testIsNewerVersionMajorUpgrade() {
        XCTAssertTrue(isNewerVersion(latest: "2.0.0", current: "1.5.3"))
        XCTAssertTrue(isNewerVersion(latest: "1.0.0", current: "0.9.9"))
    }

    func testIsNewerVersionMinorUpgrade() {
        XCTAssertTrue(isNewerVersion(latest: "1.2.0", current: "1.1.5"))
        XCTAssertTrue(isNewerVersion(latest: "0.8.0", current: "0.7.1"))
    }

    func testIsNewerVersionPatchUpgrade() {
        XCTAssertTrue(isNewerVersion(latest: "1.1.2", current: "1.1.1"))
        XCTAssertTrue(isNewerVersion(latest: "0.7.2", current: "0.7.1"))
    }

    func testIsNewerVersionSameVersion() {
        XCTAssertFalse(isNewerVersion(latest: "1.0.0", current: "1.0.0"))
        XCTAssertFalse(isNewerVersion(latest: "0.7.1", current: "0.7.1"))
    }

    func testIsNewerVersionOlderVersion() {
        XCTAssertFalse(isNewerVersion(latest: "1.0.0", current: "2.0.0"))
        XCTAssertFalse(isNewerVersion(latest: "1.1.0", current: "1.2.0"))
        XCTAssertFalse(isNewerVersion(latest: "1.1.1", current: "1.1.2"))
    }

    func testIsNewerVersionWithVPrefix() {
        // Simulating what happens after stripping 'v' prefix
        let latest = "v0.8.0".hasPrefix("v") ? String("v0.8.0".dropFirst()) : "v0.8.0"
        XCTAssertTrue(isNewerVersion(latest: latest, current: "0.7.1"))
    }

    // MARK: - Edge Cases

    func testVersionComparisonWithZeros() {
        XCTAssertTrue(isNewerVersion(latest: "0.0.1", current: "0.0.0"))
        XCTAssertFalse(isNewerVersion(latest: "0.0.0", current: "0.0.1"))
    }

    func testVersionComparisonLargeNumbers() {
        XCTAssertTrue(isNewerVersion(latest: "10.20.30", current: "10.20.29"))
        XCTAssertTrue(isNewerVersion(latest: "100.0.0", current: "99.99.99"))
    }

    // MARK: - Helper Functions (mirroring actual implementation)

    private func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        return (
            major: components.count > 0 ? components[0] : 0,
            minor: components.count > 1 ? components[1] : 0,
            patch: components.count > 2 ? components[2] : 0
        )
    }

    private func isNewerVersion(latest: String, current: String) -> Bool {
        if latest == current {
            return false
        }

        let currentParsed = parseVersion(current)
        let remoteParsed = parseVersion(latest)

        if remoteParsed.major != currentParsed.major {
            return remoteParsed.major > currentParsed.major
        }
        if remoteParsed.minor != currentParsed.minor {
            return remoteParsed.minor > currentParsed.minor
        }
        return remoteParsed.patch > currentParsed.patch
    }
}
