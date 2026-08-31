import AppKit
import Foundation

public struct LumiApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.coffic.lumi",
        fallbackApplicationPaths: [String] = [
            "/Applications/Lumi.app",
            "\(NSHomeDirectory())/Applications/Lumi.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum LumiProjectLauncher {
    public static let configuration = LumiApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: LumiApplicationConfiguration = configuration) {
        Task.detached(priority: .utility) {
            let appURL = applicationURL(configuration: configuration)
            await MainActor.run {
                guard let appURL else {
                    NSWorkspace.shared.open(projectURL)
                    return
                }

                let openConfiguration = NSWorkspace.OpenConfiguration()
                openConfiguration.activates = true
                NSWorkspace.shared.open(
                    [projectURL],
                    withApplicationAt: appURL,
                    configuration: openConfiguration
                )
            }
        }
    }

    public static func applicationURL(configuration: LumiApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
