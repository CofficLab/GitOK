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

    @MainActor
    public static func open(_ projectURL: URL, configuration: CursorApplicationConfiguration = configuration) {
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
