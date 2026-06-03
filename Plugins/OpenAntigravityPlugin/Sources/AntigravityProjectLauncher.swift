import AppKit
import Foundation

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

public enum AntigravityProjectLauncher {
    public static let configuration = AntigravityApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: AntigravityApplicationConfiguration = configuration) {
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

    public static func applicationURL(configuration: AntigravityApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
