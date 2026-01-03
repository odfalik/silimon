import Foundation
import Combine

/// Metric types that can be displayed
enum MetricType: String, CaseIterable, Codable, Identifiable {
    case power
    case memory
    case cpu
    case gpu

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .power: return "Power"
        case .memory: return "Memory"
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        }
    }

    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .memory: return "memorychip"
        case .cpu: return "cpu.fill"
        case .gpu: return "cpu"
        }
    }

    var color: String {
        switch self {
        case .power: return "orange"
        case .memory: return "purple"
        case .cpu: return "blue"
        case .gpu: return "green"
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

    // MARK: - Sampling Settings

    /// Sampling interval in seconds (0.5 to 5.0)
    @Published var samplingInterval: Double {
        didSet { defaults.set(samplingInterval, forKey: Keys.samplingInterval) }
    }

    // MARK: - Startup Settings

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAgent()
        }
    }

    // MARK: - Metric Order

    @Published var metricOrder: [MetricType] {
        didSet {
            let rawValues = metricOrder.map { $0.rawValue }
            defaults.set(rawValues, forKey: Keys.metricOrder)
        }
    }

    // MARK: - Computed Properties

    /// Get whether a metric is shown in the status bar
    func isShownInBar(_ metric: MetricType) -> Bool {
        switch metric {
        case .power: return showPowerInStatusBar
        case .memory: return showMemoryInStatusBar
        case .cpu: return showCPUInStatusBar
        case .gpu: return showGPUInStatusBar
        }
    }

    /// Set whether a metric is shown in the status bar
    func setShownInBar(_ metric: MetricType, _ value: Bool) {
        switch metric {
        case .power: showPowerInStatusBar = value
        case .memory: showMemoryInStatusBar = value
        case .cpu: showCPUInStatusBar = value
        case .gpu: showGPUInStatusBar = value
        }
    }

    /// Get whether a metric module is enabled (shown in panel)
    func isModuleEnabled(_ metric: MetricType) -> Bool {
        switch metric {
        case .power: return powerModuleEnabled
        case .memory: return memoryModuleEnabled
        case .cpu: return cpuModuleEnabled
        case .gpu: return gpuModuleEnabled
        }
    }

    /// Set whether a metric module is enabled (shown in panel)
    func setModuleEnabled(_ metric: MetricType, _ value: Bool) {
        switch metric {
        case .power: powerModuleEnabled = value
        case .memory: memoryModuleEnabled = value
        case .cpu: cpuModuleEnabled = value
        case .gpu: gpuModuleEnabled = value
        }
    }

    /// Returns true if powermetrics is needed (any module that requires it is enabled)
    var needsPowerMetrics: Bool {
        gpuModuleEnabled || cpuModuleEnabled || powerModuleEnabled
    }

    // MARK: - Keys

    private enum Keys {
        static let showPowerInStatusBar = "showPowerInStatusBar"
        static let showMemoryInStatusBar = "showMemoryInStatusBar"
        static let showCPUInStatusBar = "showCPUInStatusBar"
        static let showGPUInStatusBar = "showGPUInStatusBar"
        static let gpuModuleEnabled = "gpuModuleEnabled"
        static let cpuModuleEnabled = "cpuModuleEnabled"
        static let memoryModuleEnabled = "memoryModuleEnabled"
        static let powerModuleEnabled = "powerModuleEnabled"
        static let samplingInterval = "samplingInterval"
        static let launchAtLogin = "launchAtLogin"
        static let metricOrder = "metricOrder"
    }

    // MARK: - Initialization

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.showPowerInStatusBar: true,
            Keys.showMemoryInStatusBar: false,
            Keys.showCPUInStatusBar: false,
            Keys.showGPUInStatusBar: false,
            Keys.gpuModuleEnabled: true,
            Keys.cpuModuleEnabled: true,
            Keys.memoryModuleEnabled: true,
            Keys.powerModuleEnabled: true,
            Keys.samplingInterval: 1.0,
            Keys.launchAtLogin: false
        ])

        // Load saved values
        showPowerInStatusBar = defaults.bool(forKey: Keys.showPowerInStatusBar)
        showMemoryInStatusBar = defaults.bool(forKey: Keys.showMemoryInStatusBar)
        showCPUInStatusBar = defaults.bool(forKey: Keys.showCPUInStatusBar)
        showGPUInStatusBar = defaults.bool(forKey: Keys.showGPUInStatusBar)
        gpuModuleEnabled = defaults.bool(forKey: Keys.gpuModuleEnabled)
        cpuModuleEnabled = defaults.bool(forKey: Keys.cpuModuleEnabled)
        memoryModuleEnabled = defaults.bool(forKey: Keys.memoryModuleEnabled)
        powerModuleEnabled = defaults.bool(forKey: Keys.powerModuleEnabled)
        samplingInterval = defaults.double(forKey: Keys.samplingInterval)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

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
}
