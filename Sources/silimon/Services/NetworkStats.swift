import Foundation

/// Collects network statistics using system APIs (no sudo required)
class NetworkStats {
    struct Result {
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        var bytesInPerSec: Double = 0
        var bytesOutPerSec: Double = 0
    }

    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastTimestamp: Date?

    func collect() -> Result {
        var result = Result()

        let (bytesIn, bytesOut) = getNetworkBytes()
        result.bytesIn = bytesIn
        result.bytesOut = bytesOut

        // Calculate per-second rates
        if let lastTime = lastTimestamp {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed > 0 {
                let deltaIn = bytesIn >= lastBytesIn ? bytesIn - lastBytesIn : bytesIn
                let deltaOut = bytesOut >= lastBytesOut ? bytesOut - lastBytesOut : bytesOut
                result.bytesInPerSec = Double(deltaIn) / elapsed
                result.bytesOutPerSec = Double(deltaOut) / elapsed
            }
        }

        // Store for next calculation
        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastTimestamp = Date()

        return result
    }

    private func getNetworkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee

            // Only count AF_LINK (link-layer) addresses for byte counts
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: interface.ifa_name)

                // Skip loopback interface
                if name != "lo0" {
                    if let data = interface.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        bytesIn += UInt64(networkData.ifi_ibytes)
                        bytesOut += UInt64(networkData.ifi_obytes)
                    }
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }

        return (bytesIn, bytesOut)
    }

    /// Format bytes per second as human-readable string
    static func formatBytesPerSec(_ bytesPerSec: Double) -> String {
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

    /// Format bytes per second as compact string (for menu bar)
    static func formatCompact(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%.0f", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.0f", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f", bytesPerSec / (1024 * 1024))
        }
    }

    /// Get unit for compact format
    static func formatCompactUnit(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return "B/s"
        } else if bytesPerSec < 1024 * 1024 {
            return "KB/s"
        } else {
            return "MB/s"
        }
    }
}
