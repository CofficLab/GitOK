import AppKit
import Foundation

public struct CursorApplicationConfiguration: Equatable, Sendable {
    public let bundleIdentifier: String
    public let fallbackApplicationPaths: [String]

    public init(
        bundleIdentifier: String = "com.todesktop.230313mzl4w4u92",
        fallbackApplicationPaths: [String] = [
            "/Applications/Cursor.app",
            "\(NSHomeDirectory())/Applications/Cursor.app",
        ]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.fallbackApplicationPaths = fallbackApplicationPaths
    }
}

public enum CursorProjectLauncher {
    public static let configuration = CursorApplicationConfiguration()

    public static var isInstalled: Bool {
        applicationURL() != nil
    }

    @MainActor
    public static func open(_ projectURL: URL, configuration: CursorApplicationConfiguration = configuration) {
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

    public static func applicationURL(configuration: CursorApplicationConfiguration = configuration) -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: configuration.bundleIdentifier) {
            return appURL
        }

        for path in configuration.fallbackApplicationPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
