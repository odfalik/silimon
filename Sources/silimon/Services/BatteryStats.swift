import Foundation
import IOKit.ps

/// Collects battery statistics using IOKit
class BatteryStats {
    struct Stats {
        var level: Double = 0           // 0-100%
        var isCharging: Bool = false
        var timeRemaining: Int? = nil   // Minutes, nil if calculating or N/A
    }

    func collect() -> Stats {
        var stats = Stats()

        // Get power source info
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return stats
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // Check if this is a battery
            guard let type = info[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType else {
                continue
            }

            // Battery level
            if let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                stats.level = Double(currentCapacity) / Double(maxCapacity) * 100
            }

            // Charging state
            if let isCharging = info[kIOPSIsChargingKey] as? Bool {
                stats.isCharging = isCharging
            }

            // Time remaining
            if let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 {
                stats.timeRemaining = timeToEmpty
            } else if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                stats.timeRemaining = timeToFull
            }

            break  // Only process first battery
        }

        return stats
    }
}
