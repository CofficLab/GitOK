import Cocoa
import SwiftUI

/// 打开 GitHub Desktop 的工具栏按钮视图
/// 提供一键用 GitHub Desktop 打开当前项目的功能
struct BtnOpenGitHubDesktopView: View {
    /// 数据提供者（包含当前项目）
    @EnvironmentObject var g: DataProvider

    /// 单例实例
    static let shared = BtnOpenGitHubDesktopView()

    private init() {}

    /// 视图主体
    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.githubDesktop, useRealIcon: true)
                .help("用 GitHub Desktop 打开")
        }
    }

    /// 打开 GitHub Desktop 并传入本地仓库路径
    /// - Parameter path: 本地仓库路径
    func openInGitHubDesktop(path: String) {
        // 优先使用 URL Scheme（更兼容）
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        if let url = URL(string: "github-desktop://openLocalRepo?path=\(encodedPath)") {
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        // 失败则回退到通过应用打开指定目录
        if let appURL = appURL() {
            NSWorkspace.shared.open([URL(fileURLWithPath: path)], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }

    /// 获取 GitHub Desktop 的应用 URL
    /// - Returns: 应用 URL，如果找不到则返回 nil
    func appURL() -> URL? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.github.GitHubClient") {
            return appURL
        }
        let paths = [
            "/Applications/GitHub Desktop.app",
            NSHomeDirectory() + "/Applications/GitHub Desktop.app"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    /// 获取 GitHub Desktop 的应用图标
    /// - Returns: SwiftUI Image，如果无法获取则返回 nil
    func appIcon() -> Image? {
        guard let appURL = appURL() else { return nil }
        let nsImage = NSWorkspace.shared.icon(forFile: appURL.path)
        return Image(nsImage: nsImage)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
