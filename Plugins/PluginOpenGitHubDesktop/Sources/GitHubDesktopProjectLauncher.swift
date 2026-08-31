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

/// Abstracts macOS application discovery so the launcher can be unit tested
/// without depending on NSWorkspace or the real file system.
public protocol AppLocator: Sendable {
    func urlForApplication(withBundleIdentifier bundleID: String) -> URL?
    func fileExists(atPath path: String) -> Bool
}

/// Default production locator that delegates to NSWorkspace and FileManager.
public struct SystemAppLocator: AppLocator {
    public init() {}

    public func urlForApplication(withBundleIdentifier bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    public func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

/// Abstracts opening a project with GitHub Desktop so tests can verify launch behavior.
public protocol GitHubDesktopWorkspace: Sendable {
    func openProject(_ projectURL: URL, withApplicationAt appURL: URL)
}

/// Default production workspace that opens the local repository folder in GitHub Desktop.
public struct SystemGitHubDesktopWorkspace: GitHubDesktopWorkspace {
    public init() {}

    public func openProject(_ projectURL: URL, withApplicationAt appURL: URL) {
        NSWorkspace.shared.open(
            [projectURL],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}

public enum GitHubDesktopProjectLauncher {
    public static let configuration = GitHubDesktopApplicationConfiguration()

    /// The locator used for production calls. Overridable for testing.
    public static nonisolated(unsafe) var locator: any AppLocator = SystemAppLocator()

    /// The workspace used for production calls. Overridable for testing.
    public static nonisolated(unsafe) var workspace: any GitHubDesktopWorkspace = SystemGitHubDesktopWorkspace()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(
        _ projectURL: URL,
        configuration: GitHubDesktopApplicationConfiguration = configuration,
        locator: any AppLocator = locator,
        workspace: any GitHubDesktopWorkspace = workspace
    ) {
        guard let appURL = applicationURL(configuration: configuration, locator: locator) else { return }

        workspace.openProject(projectURL, withApplicationAt: appURL)
    }

    public static func applicationURL(
        configuration: GitHubDesktopApplicationConfiguration = configuration,
        locator: any AppLocator = locator
    ) -> URL? {
        if let appURL = locator.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where locator.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
