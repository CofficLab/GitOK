import AppKit
import Foundation

public struct KiroApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "dev.kiro.desktop",
        fallbackApplicationPaths: [String] = [
            "/Applications/Kiro.app",
            "\(NSHomeDirectory())/Applications/Kiro.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum KiroProjectLauncher {
    public static let configuration = KiroApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: KiroApplicationConfiguration = configuration) {
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

    public static func applicationURL(configuration: KiroApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
