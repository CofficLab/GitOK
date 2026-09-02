import Foundation

/// 可在当前项目文件夹上打开的「应用目标」。
///
/// 复刻旧版 11 个 `PluginOpen*` 插件（OpenFinder / OpenTerminal / OpenVSCode /
/// OpenCursor / OpenXcode / OpenTrae / OpenAntigravity / OpenGitHubDesktop /
/// OpenKiro / OpenLumi / OpenRemote）的打开目标清单。
public enum OpenTarget: String, CaseIterable, Identifiable, Sendable {
    case finder
    case terminal
    case vscode
    case cursor
    case xcode
    case trae
    case antigravity
    case githubDesktop
    case kiro
    case lumi
    case remote

    public var id: String { rawValue }

    /// SF Symbol 图标。
    public var systemImage: String {
        switch self {
        case .finder: "folder"
        case .terminal: "terminal"
        case .vscode, .trae: "chevron.left.forwardslash.chevron.right"
        case .cursor: "cursorarrow"
        case .xcode: "hammer"
        case .antigravity: "paperplane"
        case .githubDesktop: "arrow.triangle.branch"
        case .kiro: "sparkles"
        case .lumi: "sparkle"
        case .remote: "link"
        }
    }

    /// 展示名称。
    public var displayName: String {
        switch self {
        case .finder: "Finder"
        case .terminal: "Terminal"
        case .vscode: "VS Code"
        case .cursor: "Cursor"
        case .xcode: "Xcode"
        case .trae: "Trae"
        case .antigravity: "Antigravity"
        case .githubDesktop: "GitHub Desktop"
        case .kiro: "Kiro"
        case .lumi: "Lumi"
        case .remote: "Remote"
        }
    }

    /// 帮助文案。
    public var helpText: String {
        self == .remote ? "Open Remote Repository" : "Open in \(displayName)"
    }

    /// 工具栏 order（旧版顺序：Finder 400 → Remote 500）。
    public var toolbarOrder: Int {
        switch self {
        case .finder: 10
        case .terminal: 20
        case .vscode: 30
        case .cursor: 40
        case .xcode: 50
        case .trae: 60
        case .antigravity: 70
        case .githubDesktop: 80
        case .kiro: 90
        case .lumi: 100
        case .remote: 110
        }
    }

    /// 首选 bundle identifier（用于按 bundle id 定位应用）。
    var bundleIdentifier: String {
        switch self {
        case .finder: "com.apple.finder"
        case .terminal: "com.apple.Terminal"
        case .vscode: "com.microsoft.VSCode"
        case .cursor: "com.todesktop.230313mzl4w4u92"
        case .xcode: "com.apple.dt.Xcode"
        case .trae: "com.trae.app"
        case .antigravity: "com.google.antigravity"
        case .githubDesktop: "com.github.GitHubClient"
        case .kiro: "dev.kiro.desktop"
        case .lumi: "com.coffic.lumi"
        case .remote: ""
        }
    }

    /// 回退应用路径（bundle id 解析失败时按路径查找）。
    var fallbackPaths: [String] {
        let home = NSHomeDirectory()
        return switch self {
        case .finder:
            ["/System/Library/CoreServices/Finder.app"]
        case .terminal:
            ["/System/Applications/Utilities/Terminal.app"]
        case .vscode:
            ["/Applications/Visual Studio Code.app", "\(home)/Applications/Visual Studio Code.app"]
        case .cursor:
            ["/Applications/Cursor.app", "\(home)/Applications/Cursor.app"]
        case .xcode:
            ["/Applications/Xcode.app"]
        case .trae:
            ["/Applications/Trae.app", "\(home)/Applications/Trae.app"]
        case .antigravity:
            ["/Applications/Antigravity.app", "\(home)/Applications/Antigravity.app"]
        case .githubDesktop:
            ["/Applications/GitHub Desktop.app"]
        case .kiro:
            ["/Applications/Kiro.app", "\(home)/Applications/Kiro.app"]
        case .lumi:
            ["/Applications/Lumi.app", "\(home)/Applications/Lumi.app"]
        case .remote:
            []
        }
    }

    /// 该目标是否始终可用（Remote 通过浏览器打开，总是可用）。
    public var isAlwaysAvailable: Bool { self == .remote }
}
