import AppKit
import Foundation
import MagicAlert

enum ExternalEditor: String, CaseIterable, Identifiable {
    case cursor
    case vscode
    case xcode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cursor: return "Cursor"
        case .vscode: return "Visual Studio Code"
        case .xcode: return "Xcode"
        }
    }

    var description: String {
        switch self {
        case .cursor: return "用 Cursor 打开项目目录"
        case .vscode: return "用 VS Code 打开项目目录"
        case .xcode: return "用 Xcode 打开项目或目录"
        }
    }

    var iconName: String {
        switch self {
        case .cursor: return "cursorarrow"
        case .vscode: return "chevron.left.forwardslash.chevron.right"
        case .xcode: return "hammer"
        }
    }

    fileprivate var bundleIdentifier: String {
        switch self {
        case .cursor: return "com.todesktop.230313mzl4w4u92"
        case .vscode: return "com.microsoft.VSCode"
        case .xcode: return "com.apple.dt.Xcode"
        }
    }

    fileprivate var appPaths: [String] {
        switch self {
        case .cursor:
            return ["/Applications/Cursor.app", NSHomeDirectory() + "/Applications/Cursor.app"]
        case .vscode:
            return ["/Applications/Visual Studio Code.app", NSHomeDirectory() + "/Applications/Visual Studio Code.app"]
        case .xcode:
            return ["/Applications/Xcode.app"]
        }
    }
}

enum ExternalTerminal: String, CaseIterable, Identifiable {
    case terminal
    case iTerm
    case warp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .terminal: return "Terminal"
        case .iTerm: return "iTerm"
        case .warp: return "Warp"
        }
    }

    var description: String {
        switch self {
        case .terminal: return "使用 macOS Terminal 打开项目目录"
        case .iTerm: return "使用 iTerm 打开项目目录"
        case .warp: return "使用 Warp 打开项目目录"
        }
    }

    var iconName: String { "terminal" }

    fileprivate var bundleIdentifier: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iTerm: return "com.googlecode.iterm2"
        case .warp: return "dev.warp.Warp-Stable"
        }
    }

    fileprivate var appPaths: [String] {
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

final class ExternalToolSettingsStore: ObservableObject {
    static let shared = ExternalToolSettingsStore()

    private let defaultEditorKey = "ExternalTools.DefaultEditor"
    private let defaultTerminalKey = "ExternalTools.DefaultTerminal"

    @Published var defaultEditor: ExternalEditor {
        didSet {
            UserDefaults.standard.set(defaultEditor.rawValue, forKey: defaultEditorKey)
        }
    }

    @Published var defaultTerminal: ExternalTerminal {
        didSet {
            UserDefaults.standard.set(defaultTerminal.rawValue, forKey: defaultTerminalKey)
        }
    }

    private init() {
        let editorRaw = UserDefaults.standard.string(forKey: defaultEditorKey)
        defaultEditor = editorRaw.flatMap(ExternalEditor.init(rawValue:)) ?? .cursor

        let terminalRaw = UserDefaults.standard.string(forKey: defaultTerminalKey)
        defaultTerminal = terminalRaw.flatMap(ExternalTerminal.init(rawValue:)) ?? .terminal
    }

    func isInstalled(_ editor: ExternalEditor) -> Bool {
        appURL(bundleIdentifier: editor.bundleIdentifier, appPaths: editor.appPaths) != nil
    }

    func isInstalled(_ terminal: ExternalTerminal) -> Bool {
        appURL(bundleIdentifier: terminal.bundleIdentifier, appPaths: terminal.appPaths) != nil
    }

    func openDefaultEditor(for projectURL: URL) {
        let editor = resolvedEditor()
        guard let appURL = appURL(bundleIdentifier: editor.bundleIdentifier, appPaths: editor.appPaths) else {
            alert_error("未找到可用编辑器")
            return
        }

        NSWorkspace.shared.open(
            [projectURL],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )

        if editor != defaultEditor {
            alert_info("默认编辑器不可用，已使用 \(editor.displayName) 打开")
        }
    }

    func openDefaultTerminal(for projectURL: URL) {
        let terminal = resolvedTerminal()
        guard let appURL = appURL(bundleIdentifier: terminal.bundleIdentifier, appPaths: terminal.appPaths) else {
            alert_error("未找到可用终端")
            return
        }

        NSWorkspace.shared.open(
            [projectURL],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )

        if terminal != defaultTerminal {
            alert_info("默认终端不可用，已使用 \(terminal.displayName) 打开")
        }
    }

    private func resolvedEditor() -> ExternalEditor {
        if isInstalled(defaultEditor) {
            return defaultEditor
        }
        return ExternalEditor.allCases.first(where: isInstalled) ?? defaultEditor
    }

    private func resolvedTerminal() -> ExternalTerminal {
        if isInstalled(defaultTerminal) {
            return defaultTerminal
        }
        return ExternalTerminal.allCases.first(where: isInstalled) ?? defaultTerminal
    }

    private func appURL(bundleIdentifier: String, appPaths: [String]) -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url
        }

        for path in appPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
