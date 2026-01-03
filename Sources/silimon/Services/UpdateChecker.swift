import Foundation
import Combine

/// Checks GitHub releases for available updates
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published private(set) var updateAvailable: Bool = false
    @Published private(set) var latestVersion: String?
    @Published private(set) var releaseURL: URL?
    @Published private(set) var isChecking: Bool = false

    private let currentVersion: String
    private let githubRepo = "odfalik/silimon"
    private var checkTimer: Timer?

    init(currentVersion: String = version) {
        self.currentVersion = currentVersion
    }

    /// Check for updates on launch and periodically (every 6 hours)
    func startPeriodicChecks() {
        // Check immediately on launch
        checkForUpdates()

        // Then check every 6 hours
        checkTimer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }

    func stopPeriodicChecks() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    /// Manually trigger an update check
    func checkForUpdates() {
        guard !isChecking else { return }

        isChecking = true

        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false

                guard let data = data,
                      error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String,
                      let htmlURL = json["html_url"] as? String else {
                    return
                }

                // Remove 'v' prefix if present (e.g., "v0.3.0" -> "0.3.0")
                let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

                self?.latestVersion = latestVersion
                self?.releaseURL = URL(string: htmlURL)
                self?.updateAvailable = self?.isNewerVersion(latestVersion) ?? false
            }
        }.resume()
    }

    /// Compare versions using semantic versioning
    private func isNewerVersion(_ latest: String) -> Bool {
        // Quick check: if versions are identical strings, no update needed
        if latest == currentVersion {
            return false
        }

        let current = parseVersion(currentVersion)
        let remote = parseVersion(latest)

        // Compare major.minor.patch
        if remote.major != current.major {
            return remote.major > current.major
        }
        if remote.minor != current.minor {
            return remote.minor > current.minor
        }
        return remote.patch > current.patch
    }

    private func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        return (
            major: components.count > 0 ? components[0] : 0,
            minor: components.count > 1 ? components[1] : 0,
            patch: components.count > 2 ? components[2] : 0
        )
    }
}
