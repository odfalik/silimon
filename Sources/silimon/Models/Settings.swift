import Foundation
import Combine
import SwiftUI

/// Status bar display mode
enum StatusBarMode: String, CaseIterable, Codable {
    case text = "text"
    case sparkline = "sparkline"

    var displayName: String {
        switch self {
        case .text: return "Numbers"
        case .sparkline: return "Graph"
        }
    }
}

/// Sparkline width options
enum SparklineWidth: String, CaseIterable, Codable {
    case narrow = "narrow"
    case medium = "medium"
    case wide = "wide"

    var displayName: String {
        switch self {
        case .narrow: return "Narrow"
        case .medium: return "Medium"
        case .wide: return "Wide"
        }
    }

    var pixels: CGFloat {
        switch self {
        case .narrow: return 100
        case .medium: return 160
        case .wide: return 220
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else {
            return "#FFFFFF"
        }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

/// Metric types that can be displayed
enum MetricType: String, CaseIterable, Codable, Identifiable {
    case power
    case cpu
    case gpu
    case memory
    case network
    case battery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .power: return "Power"
        case .memory: return "Memory"
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .network: return "Network"
        case .battery: return "Battery"
        }
    }

    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .memory: return "memorychip"
        case .cpu: return "cpu.fill"
        case .gpu: return "cpu"
        case .network: return "network"
        case .battery: return "battery.100"
        }
    }

    var color: String {
        switch self {
        case .power: return "orange"
        case .memory: return "purple"
        case .cpu: return "blue"
        case .gpu: return "green"
        case .network: return "cyan"
        case .battery: return "green"
        }
    }
}

/// App settings with UserDefaults persistence
class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Status Bar Display Options

    @Published var showPowerInStatusBar: Bool {
        didSet { defaults.set(showPowerInStatusBar, forKey: Keys.showPowerInStatusBar) }
    }

    @Published var showMemoryInStatusBar: Bool {
        didSet { defaults.set(showMemoryInStatusBar, forKey: Keys.showMemoryInStatusBar) }
    }

    @Published var showCPUInStatusBar: Bool {
        didSet { defaults.set(showCPUInStatusBar, forKey: Keys.showCPUInStatusBar) }
    }

    @Published var showGPUInStatusBar: Bool {
        didSet { defaults.set(showGPUInStatusBar, forKey: Keys.showGPUInStatusBar) }
    }

    @Published var showBatteryInStatusBar: Bool {
        didSet { defaults.set(showBatteryInStatusBar, forKey: Keys.showBatteryInStatusBar) }
    }

    @Published var showNetworkInStatusBar: Bool {
        didSet { defaults.set(showNetworkInStatusBar, forKey: Keys.showNetworkInStatusBar) }
    }

    // MARK: - Module Enable/Disable

    @Published var gpuModuleEnabled: Bool {
        didSet { defaults.set(gpuModuleEnabled, forKey: Keys.gpuModuleEnabled) }
    }

    @Published var cpuModuleEnabled: Bool {
        didSet { defaults.set(cpuModuleEnabled, forKey: Keys.cpuModuleEnabled) }
    }

    @Published var memoryModuleEnabled: Bool {
        didSet { defaults.set(memoryModuleEnabled, forKey: Keys.memoryModuleEnabled) }
    }

    @Published var powerModuleEnabled: Bool {
        didSet { defaults.set(powerModuleEnabled, forKey: Keys.powerModuleEnabled) }
    }

    @Published var batteryModuleEnabled: Bool {
        didSet { defaults.set(batteryModuleEnabled, forKey: Keys.batteryModuleEnabled) }
    }

    @Published var networkModuleEnabled: Bool {
        didSet { defaults.set(networkModuleEnabled, forKey: Keys.networkModuleEnabled) }
    }

    // MARK: - Sampling Settings

    /// Sampling interval in seconds (0.5 to 5.0)
    @Published var samplingInterval: Double {
        didSet { defaults.set(samplingInterval, forKey: Keys.samplingInterval) }
    }

    /// History duration in seconds (how much data to retain)
    @Published var historyDuration: Double {
        didSet { defaults.set(historyDuration, forKey: Keys.historyDuration) }
    }

    // MARK: - Startup Settings

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAgent()
        }
    }

    // MARK: - Status Bar Mode

    @Published var statusBarMode: StatusBarMode {
        didSet { defaults.set(statusBarMode.rawValue, forKey: Keys.statusBarMode) }
    }

    @Published var sparklineWidth: SparklineWidth {
        didSet { defaults.set(sparklineWidth.rawValue, forKey: Keys.sparklineWidth) }
    }

    // MARK: - Metric Colors (stored as hex strings)

    @Published var powerColorHex: String {
        didSet { defaults.set(powerColorHex, forKey: Keys.powerColor) }
    }
    @Published var cpuColorHex: String {
        didSet { defaults.set(cpuColorHex, forKey: Keys.cpuColor) }
    }
    @Published var gpuColorHex: String {
        didSet { defaults.set(gpuColorHex, forKey: Keys.gpuColor) }
    }
    @Published var memoryColorHex: String {
        didSet { defaults.set(memoryColorHex, forKey: Keys.memoryColor) }
    }
    @Published var networkColorHex: String {
        didSet { defaults.set(networkColorHex, forKey: Keys.networkColor) }
    }
    @Published var batteryColorHex: String {
        didSet { defaults.set(batteryColorHex, forKey: Keys.batteryColor) }
    }

    /// Get SwiftUI Color for a metric
    func color(for metric: MetricType) -> Color {
        switch metric {
        case .power: return Color(hex: powerColorHex)
        case .cpu: return Color(hex: cpuColorHex)
        case .gpu: return Color(hex: gpuColorHex)
        case .memory: return Color(hex: memoryColorHex)
        case .network: return Color(hex: networkColorHex)
        case .battery: return Color(hex: batteryColorHex)
        }
    }

    /// Get NSColor for a metric (for StatusBarView)
    func nsColor(for metric: MetricType) -> NSColor {
        NSColor(color(for: metric))
    }

    /// Set color for a metric
    func setColor(_ color: Color, for metric: MetricType) {
        let hex = color.toHex()
        switch metric {
        case .power: powerColorHex = hex
        case .cpu: cpuColorHex = hex
        case .gpu: gpuColorHex = hex
        case .memory: memoryColorHex = hex
        case .network: networkColorHex = hex
        case .battery: batteryColorHex = hex
        }
    }

    /// Color binding for SwiftUI ColorPicker
    func colorBinding(for metric: MetricType) -> Binding<Color> {
        Binding(
            get: { self.color(for: metric) },
            set: { self.setColor($0, for: metric) }
        )
    }

    // MARK: - Metric Order

    @Published var metricOrder: [MetricType] {
        didSet {
            let rawValues = metricOrder.map { $0.rawValue }
            defaults.set(rawValues, forKey: Keys.metricOrder)
        }
    }

    // MARK: - Star Repo Prompt

    /// Date when the app was first launched (nil if never set)
    private(set) var firstLaunchDate: Date? {
        didSet {
            if let date = firstLaunchDate {
                defaults.set(date, forKey: Keys.firstLaunchDate)
            }
        }
    }

    /// Whether we've already asked the user to star the repo
    @Published var hasAskedToStarRepo: Bool {
        didSet { defaults.set(hasAskedToStarRepo, forKey: Keys.hasAskedToStarRepo) }
    }

    /// Number of times the app has been launched
    private(set) var launchCount: Int {
        didSet { defaults.set(launchCount, forKey: Keys.launchCount) }
    }

    // MARK: - Computed Properties

    /// Get whether a metric is shown in the status bar
    func isShownInBar(_ metric: MetricType) -> Bool {
        switch metric {
        case .power: return showPowerInStatusBar
        case .memory: return showMemoryInStatusBar
        case .cpu: return showCPUInStatusBar
        case .gpu: return showGPUInStatusBar
        case .network: return showNetworkInStatusBar
        case .battery: return showBatteryInStatusBar
        }
    }

    /// Set whether a metric is shown in the status bar
    func setShownInBar(_ metric: MetricType, _ value: Bool) {
        switch metric {
        case .power: showPowerInStatusBar = value
        case .memory: showMemoryInStatusBar = value
        case .cpu: showCPUInStatusBar = value
        case .gpu: showGPUInStatusBar = value
        case .network: showNetworkInStatusBar = value
        case .battery: showBatteryInStatusBar = value
        }
    }

    /// Get whether a metric module is enabled (shown in panel)
    func isModuleEnabled(_ metric: MetricType) -> Bool {
        switch metric {
        case .power: return powerModuleEnabled
        case .memory: return memoryModuleEnabled
        case .cpu: return cpuModuleEnabled
        case .gpu: return gpuModuleEnabled
        case .network: return networkModuleEnabled
        case .battery: return batteryModuleEnabled
        }
    }

    /// Set whether a metric module is enabled (shown in panel)
    func setModuleEnabled(_ metric: MetricType, _ value: Bool) {
        switch metric {
        case .power: powerModuleEnabled = value
        case .memory: memoryModuleEnabled = value
        case .cpu: cpuModuleEnabled = value
        case .gpu: gpuModuleEnabled = value
        case .network: networkModuleEnabled = value
        case .battery: batteryModuleEnabled = value
        }
    }

    /// Returns true if IOReport sampling is needed (any power/CPU/GPU module is enabled)
    var needsPowerMetrics: Bool {
        gpuModuleEnabled || cpuModuleEnabled || powerModuleEnabled
    }

    /// Returns true if we should show the "star the repo" prompt
    var shouldShowStarPrompt: Bool {
        // Don't show if we've already asked
        guard !hasAskedToStarRepo else { return false }

        // Don't show if app hasn't been launched enough times (3+ launches)
        guard launchCount >= 3 else { return false }

        // Don't show if app hasn't been running long enough (3+ days)
        guard let firstLaunch = firstLaunchDate else { return false }
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        guard daysSinceFirstLaunch >= 3 else { return false }

        // Only show if git appears to be configured on the system
        return hasGitConfigured
    }

    /// Check if git appears to be configured on the system
    private var hasGitConfigured: Bool {
        // Check for ~/.gitconfig
        let home = FileManager.default.homeDirectoryForCurrentUser
        let gitconfig = home.appendingPathComponent(".gitconfig")
        if FileManager.default.fileExists(atPath: gitconfig.path) {
            return true
        }

        // Check for ~/.config/git/config
        let gitConfigAlt = home.appendingPathComponent(".config/git/config")
        if FileManager.default.fileExists(atPath: gitConfigAlt.path) {
            return true
        }

        return false
    }

    // MARK: - Keys

    private enum Keys {
        static let showPowerInStatusBar = "showPowerInStatusBar"
        static let showMemoryInStatusBar = "showMemoryInStatusBar"
        static let showCPUInStatusBar = "showCPUInStatusBar"
        static let showGPUInStatusBar = "showGPUInStatusBar"
        static let showBatteryInStatusBar = "showBatteryInStatusBar"
        static let showNetworkInStatusBar = "showNetworkInStatusBar"
        static let gpuModuleEnabled = "gpuModuleEnabled"
        static let cpuModuleEnabled = "cpuModuleEnabled"
        static let memoryModuleEnabled = "memoryModuleEnabled"
        static let powerModuleEnabled = "powerModuleEnabled"
        static let batteryModuleEnabled = "batteryModuleEnabled"
        static let networkModuleEnabled = "networkModuleEnabled"
        static let samplingInterval = "samplingInterval"
        static let historyDuration = "historyDuration"
        static let launchAtLogin = "launchAtLogin"
        static let metricOrder = "metricOrder"
        static let statusBarMode = "statusBarMode"
        static let sparklineWidth = "sparklineWidth"
        static let firstLaunchDate = "firstLaunchDate"
        static let hasAskedToStarRepo = "hasAskedToStarRepo"
        static let launchCount = "launchCount"
        // Metric colors
        static let powerColor = "color.power"
        static let cpuColor = "color.cpu"
        static let gpuColor = "color.gpu"
        static let memoryColor = "color.memory"
        static let networkColor = "color.network"
        static let batteryColor = "color.battery"
    }

    // Default colors (hex)
    private enum DefaultColors {
        static let power = "#FF9500"    // orange
        static let cpu = "#007AFF"      // blue
        static let gpu = "#34C759"      // green
        static let memory = "#AF52DE"   // purple
        static let network = "#5AC8FA"  // cyan
        static let battery = "#FFCC00"  // yellow
    }

    // MARK: - Initialization

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.showPowerInStatusBar: false,
            Keys.showMemoryInStatusBar: true,
            Keys.showCPUInStatusBar: true,
            Keys.showGPUInStatusBar: true,
            Keys.showBatteryInStatusBar: false,
            Keys.gpuModuleEnabled: true,
            Keys.cpuModuleEnabled: true,
            Keys.memoryModuleEnabled: true,
            Keys.powerModuleEnabled: true,
            Keys.batteryModuleEnabled: true,
            Keys.networkModuleEnabled: true,
            Keys.showNetworkInStatusBar: false,
            Keys.samplingInterval: 1.0,
            Keys.historyDuration: 60.0,
            Keys.launchAtLogin: false,
            Keys.statusBarMode: StatusBarMode.sparkline.rawValue,
            Keys.sparklineWidth: SparklineWidth.medium.rawValue
        ])

        // Load saved values
        showPowerInStatusBar = defaults.bool(forKey: Keys.showPowerInStatusBar)
        showMemoryInStatusBar = defaults.bool(forKey: Keys.showMemoryInStatusBar)
        showCPUInStatusBar = defaults.bool(forKey: Keys.showCPUInStatusBar)
        showGPUInStatusBar = defaults.bool(forKey: Keys.showGPUInStatusBar)
        showBatteryInStatusBar = defaults.bool(forKey: Keys.showBatteryInStatusBar)
        showNetworkInStatusBar = defaults.bool(forKey: Keys.showNetworkInStatusBar)
        gpuModuleEnabled = defaults.bool(forKey: Keys.gpuModuleEnabled)
        cpuModuleEnabled = defaults.bool(forKey: Keys.cpuModuleEnabled)
        memoryModuleEnabled = defaults.bool(forKey: Keys.memoryModuleEnabled)
        powerModuleEnabled = defaults.bool(forKey: Keys.powerModuleEnabled)
        batteryModuleEnabled = defaults.bool(forKey: Keys.batteryModuleEnabled)
        networkModuleEnabled = defaults.bool(forKey: Keys.networkModuleEnabled)
        samplingInterval = defaults.double(forKey: Keys.samplingInterval)
        historyDuration = defaults.double(forKey: Keys.historyDuration)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        if let modeString = defaults.string(forKey: Keys.statusBarMode),
           let mode = StatusBarMode(rawValue: modeString) {
            statusBarMode = mode
        } else {
            statusBarMode = .sparkline
        }

        // Load sparkline width
        if let widthString = defaults.string(forKey: Keys.sparklineWidth),
           let width = SparklineWidth(rawValue: widthString) {
            sparklineWidth = width
        } else {
            sparklineWidth = .medium
        }

        // Load metric colors (with defaults)
        powerColorHex = defaults.string(forKey: Keys.powerColor) ?? DefaultColors.power
        cpuColorHex = defaults.string(forKey: Keys.cpuColor) ?? DefaultColors.cpu
        gpuColorHex = defaults.string(forKey: Keys.gpuColor) ?? DefaultColors.gpu
        memoryColorHex = defaults.string(forKey: Keys.memoryColor) ?? DefaultColors.memory
        networkColorHex = defaults.string(forKey: Keys.networkColor) ?? DefaultColors.network
        batteryColorHex = defaults.string(forKey: Keys.batteryColor) ?? DefaultColors.battery

        // Load star repo prompt tracking
        hasAskedToStarRepo = defaults.bool(forKey: Keys.hasAskedToStarRepo)
        launchCount = defaults.integer(forKey: Keys.launchCount) + 1  // Increment on each launch
        defaults.set(launchCount, forKey: Keys.launchCount)
        if let savedDate = defaults.object(forKey: Keys.firstLaunchDate) as? Date {
            firstLaunchDate = savedDate
        } else {
            // First launch - record the date
            firstLaunchDate = Date()
        }

        // Load metric order
        if let savedOrder = defaults.stringArray(forKey: Keys.metricOrder) {
            metricOrder = savedOrder.compactMap { MetricType(rawValue: $0) }
            // Ensure all metrics are present
            for metric in MetricType.allCases where !metricOrder.contains(metric) {
                metricOrder.append(metric)
            }
        } else {
            metricOrder = MetricType.allCases.map { $0 }
        }

        // Ensure sampling interval is within valid range
        if samplingInterval < 0.5 || samplingInterval > 5.0 {
            samplingInterval = 1.0
        }

        // Ensure history duration is within valid range
        if historyDuration < 30 || historyDuration > 300 {
            historyDuration = 60.0
        }
    }

    // MARK: - Launch Agent Management

    private var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.silimon.app.plist")
    }

    private func updateLaunchAgent() {
        if launchAtLogin {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }

    private func installLaunchAgent() {
        // Get the path to the current executable
        guard let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments.first else {
            return
        }

        // Resolve to absolute path
        let resolvedPath: String
        if executablePath.hasPrefix("/") {
            resolvedPath = executablePath
        } else {
            let currentDir = FileManager.default.currentDirectoryPath
            resolvedPath = (currentDir as NSString).appendingPathComponent(executablePath)
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.silimon.app</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(resolvedPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """

        do {
            // Ensure LaunchAgents directory exists
            let launchAgentsDir = launchAgentURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)

            // Write the plist
            try plistContent.write(to: launchAgentURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to install launch agent: \(error)")
        }
    }

    private func removeLaunchAgent() {
        try? FileManager.default.removeItem(at: launchAgentURL)
    }

    // MARK: - Reset to Defaults

    func resetToDefaults() {
        // Status bar display (GPU, CPU, Memory in bar by default)
        showPowerInStatusBar = false
        showMemoryInStatusBar = true
        showCPUInStatusBar = true
        showGPUInStatusBar = true
        showBatteryInStatusBar = false
        showNetworkInStatusBar = false

        // Module enabled (all in panel)
        gpuModuleEnabled = true
        cpuModuleEnabled = true
        memoryModuleEnabled = true
        powerModuleEnabled = true
        batteryModuleEnabled = true
        networkModuleEnabled = true

        // Sampling
        samplingInterval = 1.0
        historyDuration = 60.0

        // Display mode (graph mode, medium width)
        statusBarMode = .sparkline
        sparklineWidth = .medium

        // Colors
        powerColorHex = DefaultColors.power
        cpuColorHex = DefaultColors.cpu
        gpuColorHex = DefaultColors.gpu
        memoryColorHex = DefaultColors.memory
        networkColorHex = DefaultColors.network
        batteryColorHex = DefaultColors.battery

        // Metric order
        metricOrder = MetricType.allCases.map { $0 }
    }
}
