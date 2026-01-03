import Foundation

/// Tracks the health status of each metrics collection module
struct CollectionHealth {
    enum Status: String {
        case healthy = "healthy"
        case degraded = "degraded"
        case unavailable = "unavailable"
    }

    struct ModuleHealth {
        let status: Status
        let lastSuccess: Date?
        let errorMessage: String?

        static var unknown: ModuleHealth {
            ModuleHealth(status: .unavailable, lastSuccess: nil, errorMessage: nil)
        }

        static var healthy: ModuleHealth {
            ModuleHealth(status: .healthy, lastSuccess: Date(), errorMessage: nil)
        }
    }

    var power: ModuleHealth = .unknown
    var cpu: ModuleHealth = .unknown
    var gpu: ModuleHealth = .unknown
    var memory: ModuleHealth = .unknown
    var network: ModuleHealth = .unknown
    var battery: ModuleHealth = .unknown

    var overallStatus: Status {
        let statuses = [power, cpu, gpu, memory, network, battery]
        if statuses.allSatisfy({ $0.status == .healthy }) {
            return .healthy
        } else if statuses.contains(where: { $0.status == .unavailable }) {
            return .unavailable
        } else {
            return .degraded
        }
    }

    var hasAnyIssue: Bool {
        overallStatus != .healthy
    }

    var issueCount: Int {
        [power, cpu, gpu, memory, network, battery].filter { $0.status != .healthy }.count
    }
}
