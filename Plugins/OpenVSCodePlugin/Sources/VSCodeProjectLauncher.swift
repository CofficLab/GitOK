import AppKit
import Foundation

public struct VSCodeApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.microsoft.VSCode",
        fallbackApplicationPaths: [String] = [
            "/Applications/Visual Studio Code.app",
            "\(NSHomeDirectory())/Applications/Visual Studio Code.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum VSCodeProjectLauncher {
    public static let configuration = VSCodeApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: VSCodeApplicationConfiguration = configuration) {
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

    public static func applicationURL(configuration: VSCodeApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
