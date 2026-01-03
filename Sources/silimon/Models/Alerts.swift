import Foundation
import UserNotifications

/// Alert thresholds for various metrics
struct AlertThresholds {
    var memoryPressureEnabled: Bool = true
    var lowBatteryEnabled: Bool = true
    var lowBatteryThreshold: Double = 20  // Percent
    var thermalThrottlingEnabled: Bool = true
    var highPowerEnabled: Bool = false
    var highPowerThreshold: Double = 40  // Watts
}

/// Active alert that can be displayed to the user
struct MetricAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
    let timestamp: Date
    var dismissed: Bool = false

    enum AlertType: String {
        case memoryPressure = "memory_pressure"
        case lowBattery = "low_battery"
        case thermalThrottling = "thermal_throttling"
        case highPower = "high_power"

        var icon: String {
            switch self {
            case .memoryPressure: return "memorychip.fill"
            case .lowBattery: return "battery.25"
            case .thermalThrottling: return "thermometer.high"
            case .highPower: return "bolt.fill"
            }
        }

        var color: String {
            switch self {
            case .memoryPressure: return "red"
            case .lowBattery: return "orange"
            case .thermalThrottling: return "red"
            case .highPower: return "orange"
            }
        }
    }
}

/// Service for managing metric alerts
class AlertService: ObservableObject {
    static let shared = AlertService()

    @Published var activeAlerts: [MetricAlert] = []
    @Published var thresholds = AlertThresholds()

    private var lastAlertTimes: [MetricAlert.AlertType: Date] = [:]
    private let cooldownInterval: TimeInterval = 300  // 5 minutes between same alerts

    private init() {
        loadThresholds()
        requestNotificationPermission()
    }

    func checkMetrics(_ metrics: Metrics) {
        // Memory pressure alert
        if thresholds.memoryPressureEnabled && metrics.memoryPressure == .critical {
            triggerAlert(.memoryPressure, message: "Memory pressure is critical. Consider closing some apps.")
        }

        // Low battery alert
        if thresholds.lowBatteryEnabled &&
           !metrics.batteryIsCharging &&
           metrics.batteryLevel > 0 &&
           metrics.batteryLevel <= thresholds.lowBatteryThreshold {
            triggerAlert(.lowBattery, message: "Battery at \(Int(metrics.batteryLevel))%. Connect charger soon.")
        }

        // Thermal throttling alert
        if thresholds.thermalThrottlingEnabled && metrics.thermalPressure == .serious {
            triggerAlert(.thermalThrottling, message: "Mac is thermal throttling. Performance may be reduced.")
        }

        // High power alert
        if thresholds.highPowerEnabled && metrics.packagePower >= thresholds.highPowerThreshold {
            triggerAlert(.highPower, message: "Power consumption at \(Int(metrics.packagePower))W")
        }
    }

    private func triggerAlert(_ type: MetricAlert.AlertType, message: String) {
        // Check cooldown
        if let lastTime = lastAlertTimes[type],
           Date().timeIntervalSince(lastTime) < cooldownInterval {
            return
        }

        let alert = MetricAlert(type: type, message: message, timestamp: Date())
        activeAlerts.append(alert)
        lastAlertTimes[type] = Date()

        // Send system notification
        sendNotification(alert)

        // Keep only last 10 alerts
        if activeAlerts.count > 10 {
            activeAlerts.removeFirst()
        }
    }

    func dismissAlert(_ alert: MetricAlert) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alert.id }) {
            activeAlerts[index].dismissed = true
        }
    }

    func clearAllAlerts() {
        activeAlerts.removeAll()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(_ alert: MetricAlert) {
        let content = UNMutableNotificationContent()
        content.title = "Silimon"
        content.body = alert.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func loadThresholds() {
        let defaults = UserDefaults.standard
        thresholds.memoryPressureEnabled = defaults.object(forKey: "alert.memoryPressure") as? Bool ?? true
        thresholds.lowBatteryEnabled = defaults.object(forKey: "alert.lowBattery") as? Bool ?? true
        thresholds.lowBatteryThreshold = defaults.object(forKey: "alert.lowBatteryThreshold") as? Double ?? 20
        thresholds.thermalThrottlingEnabled = defaults.object(forKey: "alert.thermalThrottling") as? Bool ?? true
        thresholds.highPowerEnabled = defaults.object(forKey: "alert.highPower") as? Bool ?? false
        thresholds.highPowerThreshold = defaults.object(forKey: "alert.highPowerThreshold") as? Double ?? 40
    }

    func saveThresholds() {
        let defaults = UserDefaults.standard
        defaults.set(thresholds.memoryPressureEnabled, forKey: "alert.memoryPressure")
        defaults.set(thresholds.lowBatteryEnabled, forKey: "alert.lowBattery")
        defaults.set(thresholds.lowBatteryThreshold, forKey: "alert.lowBatteryThreshold")
        defaults.set(thresholds.thermalThrottlingEnabled, forKey: "alert.thermalThrottling")
        defaults.set(thresholds.highPowerEnabled, forKey: "alert.highPower")
        defaults.set(thresholds.highPowerThreshold, forKey: "alert.highPowerThreshold")
    }
}
