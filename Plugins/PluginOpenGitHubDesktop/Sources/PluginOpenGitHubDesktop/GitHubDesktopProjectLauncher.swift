import AppKit
import Foundation

public struct GitHubDesktopApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.github.GitHubClient",
        fallbackApplicationPaths: [String] = [
            "/Applications/GitHub Desktop.app",
            "\(NSHomeDirectory())/Applications/GitHub Desktop.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum GitHubDesktopProjectLauncher {
    public static let configuration = GitHubDesktopApplicationConfiguration()

    @MainActor
    public static func open(_ projectURL: URL, configuration: GitHubDesktopApplicationConfiguration = configuration) {
        if let url = localRepositoryURL(for: projectURL), NSWorkspace.shared.open(url) {
            return
        }

        guard let appURL = applicationURL(configuration: configuration) else {
            NSWorkspace.shared.open(projectURL)
            return
        }

        NSWorkspace.shared.open(
            [projectURL],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    public static func localRepositoryURL(for projectURL: URL) -> URL? {
        let path = projectURL.path
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "github-desktop://openLocalRepo?path=\(encodedPath)")
    }

    public static func applicationURL(configuration: GitHubDesktopApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
