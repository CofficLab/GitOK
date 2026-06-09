import AppKit
import Foundation

enum TerminalLauncher {
    static let defaultTerminalKey = "ExternalTools.DefaultTerminal"

    static var hasInstalledTerminal: Bool {
        ExternalTerminal.allCases.contains(where: isInstalled)
    }

    static func open(_ projectURL: URL) {
        Task.detached(priority: .utility) {
            let terminal = resolvedTerminal()
            guard let appURL = appURL(bundleIdentifier: terminal.bundleIdentifier, appPaths: terminal.appPaths) else {
                return
            }

            await MainActor.run {
                NSWorkspace.shared.open(
                    [projectURL],
                    withApplicationAt: appURL,
                    configuration: NSWorkspace.OpenConfiguration(),
                    completionHandler: nil
                )
            }
        }
    }

    static func resolvedTerminal(defaults: UserDefaults = .standard) -> ExternalTerminal {
        let configured = defaults.string(forKey: defaultTerminalKey).flatMap(ExternalTerminal.init(rawValue:))
        if let configured, isInstalled(configured) {
            return configured
        }
        return ExternalTerminal.allCases.first(where: isInstalled) ?? (configured ?? .terminal)
    }

    static func isInstalled(_ terminal: ExternalTerminal) -> Bool {
        appURL(bundleIdentifier: terminal.bundleIdentifier, appPaths: terminal.appPaths) != nil
    }

    static func appURL(bundleIdentifier: String, appPaths: [String]) -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url
        }

        for path in appPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}

public enum ExternalTerminal: String, CaseIterable, Identifiable, Sendable {
    case terminal
    case iTerm
    case warp

    public var id: String { rawValue }

    var bundleIdentifier: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iTerm: return "com.googlecode.iterm2"
        case .warp: return "dev.warp.Warp-Stable"
        }
    }

    var appPaths: [String] {
        switch self {
        case .terminal:
            return ["/System/Applications/Utilities/Terminal.app", "/Applications/Utilities/Terminal.app"]
        case .iTerm:
            return ["/Applications/iTerm.app", "/Applications/iTerm2.app", NSHomeDirectory() + "/Applications/iTerm.app"]
        case .warp:
            return ["/Applications/Warp.app", NSHomeDirectory() + "/Applications/Warp.app"]
        }
    }
}
