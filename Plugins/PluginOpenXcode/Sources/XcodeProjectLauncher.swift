import AppKit
import Foundation

public struct XcodeApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.apple.dt.Xcode",
        fallbackApplicationPaths: [String] = [
            "/Applications/Xcode.app",
            "\(NSHomeDirectory())/Applications/Xcode.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum XcodeProjectLauncher {
    public static let configuration = XcodeApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: XcodeApplicationConfiguration = configuration) {
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

    public static func applicationURL(configuration: XcodeApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
