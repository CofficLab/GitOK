import AppKit
import Foundation

// MARK: - Configuration

public struct AntigravityApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.google.antigravity",
        fallbackApplicationPaths: [String] = [
            "/Applications/Antigravity.app",
            "\(NSHomeDirectory())/Applications/Antigravity.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

// MARK: - App Locator Protocol

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

// MARK: - Launcher

public enum AntigravityProjectLauncher {
    public static let configuration = AntigravityApplicationConfiguration()

    /// The locator used for production calls. Overridable for testing.
    public static nonisolated(unsafe) var locator: any AppLocator = SystemAppLocator()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: AntigravityApplicationConfiguration = configuration) {
        Task.detached(priority: .utility) {
            let appURL = applicationURL(configuration: configuration)
            await MainActor.run {
                guard let appURL else {
                    NSWorkspace.shared.open(projectURL)
                    return
                }

                NSWorkspace.shared.open(
                    [projectURL],
                    withApplicationAt: appURL,
                    configuration: NSWorkspace.OpenConfiguration()
                )
            }
        }
    }

    public static func applicationURL(
        configuration: AntigravityApplicationConfiguration = configuration,
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
