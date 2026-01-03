import Foundation

/// Tracks onboarding state for first-time users
class OnboardingState: ObservableObject {
    static let shared = OnboardingState()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var hasSeenMetricExplanations: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenMetricExplanations, forKey: "hasSeenMetricExplanations")
        }
    }

    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasSeenMetricExplanations = UserDefaults.standard.bool(forKey: "hasSeenMetricExplanations")
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenMetricExplanations = false
    }
}

/// Educational content about metrics
struct MetricExplanation {
    let metric: MetricType
    let title: String
    let shortDescription: String
    let detailedDescription: String
    let typicalRange: String
    let whatToWatch: String

    static let all: [MetricExplanation] = [
        MetricExplanation(
            metric: .power,
            title: "Power Consumption",
            shortDescription: "Total system-on-chip power draw",
            detailedDescription: "Shows how much power your Mac's Apple Silicon chip is using, including CPU, GPU, Neural Engine, and memory controller.",
            typicalRange: "Idle: 2-5W, Light use: 5-15W, Heavy use: 20-40W",
            whatToWatch: "Sustained high power (>30W) means your Mac is working hard and may get warm."
        ),
        MetricExplanation(
            metric: .cpu,
            title: "CPU Usage",
            shortDescription: "Processor utilization across all cores",
            detailedDescription: "Apple Silicon has two types of CPU cores: E-cores (Efficiency) for light tasks and battery life, P-cores (Performance) for demanding work.",
            typicalRange: "E-cores handle most tasks. P-cores activate for heavy workloads.",
            whatToWatch: "High P-core usage means intensive processing. High E-core only is normal for everyday tasks."
        ),
        MetricExplanation(
            metric: .gpu,
            title: "GPU Usage",
            shortDescription: "Graphics processor utilization",
            detailedDescription: "The integrated GPU handles graphics, video, and some compute tasks. It shares memory with the CPU (Unified Memory Architecture).",
            typicalRange: "Idle: 0-5%, Video: 10-30%, Gaming/3D: 50-100%",
            whatToWatch: "High GPU usage during unexpected times might indicate a runaway process."
        ),
        MetricExplanation(
            metric: .memory,
            title: "Memory (RAM)",
            shortDescription: "System memory usage and pressure",
            detailedDescription: "Shows how much of your Mac's unified memory is in use. Memory pressure indicates if macOS needs to compress or swap memory.",
            typicalRange: "Nominal: Plenty of free memory. Warn: Memory getting tight. Critical: System may slow down.",
            whatToWatch: "If pressure stays at Warn/Critical, consider closing apps or upgrading RAM."
        ),
        MetricExplanation(
            metric: .network,
            title: "Network Activity",
            shortDescription: "Data transfer rates",
            detailedDescription: "Shows current download and upload speeds across all network interfaces (Wi-Fi, Ethernet, etc.).",
            typicalRange: "Varies by connection type. Gigabit: up to 125 MB/s. Wi-Fi 6: up to 150 MB/s.",
            whatToWatch: "Unexpected high upload might indicate cloud sync or background processes."
        ),
        MetricExplanation(
            metric: .battery,
            title: "Battery Status",
            shortDescription: "Charge level and power state",
            detailedDescription: "Shows current battery percentage, charging status, and estimated time remaining (when on battery) or time to full (when charging).",
            typicalRange: "Normal use: 8-12+ hours depending on workload.",
            whatToWatch: "If battery drains quickly, check for apps using high CPU/GPU."
        )
    ]

    static func explanation(for metric: MetricType) -> MetricExplanation? {
        all.first { $0.metric == metric }
    }
}
