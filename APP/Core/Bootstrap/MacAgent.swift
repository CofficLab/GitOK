import CloudKit
import MagicKit
import Foundation
import OSLog
import SwiftData
import SwiftUI

/// macOS 应用代理
/// 负责处理应用生命周期事件和系统通知
class MacAgent: NSObject, NSApplicationDelegate, ObservableObject, SuperLog, SuperEvent {
    /// 日志标识符
    nonisolated static let emoji = "🍎"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 日志标签
    var label: String { "🍎 MacAgent::" }

    /// 待打开的项目路径（通过 Dock 拖拽、open 命令、URL Scheme 触发）
    /// 使用 @Published + Combine 让 RootView 可以立即响应
    @Published var pendingOpenPath: String? = nil

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        os_log("\(self.label)已注册远程通知")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if Self.verbose {
            os_log("\(self.label)Finish Lanunching")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if Self.verbose {
            os_log("\(self.label)Will Terminate")
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if Self.verbose {
            os_log("\(self.label)Did Become Active")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appDidBecomeActive, object: self)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        if Self.verbose {
            os_log("\(self.label)Will Finish Launching")
        }

        // 不再使用 NSAppleEventManager 拦截 kAEOpenDocuments。
        //
        // 原因：拦截该事件会导致 SwiftUI WindowGroup 在冷启动时不创建窗口，
        // 因为 macOS 认为"应用自己会处理 document 事件"，SwiftUI 就不会创建默认窗口。
        // 表现为：菜单栏变成了 GitOK，但没有任何窗口出现。
        //
        // 改用 application(_:openFile:) 来接收路径，这是 NSApplicationDelegate
        // 的标准方法，不影响 SwiftUI WindowGroup 的窗口创建。
        // WindowGroup 的 .handlesExternalEvents(matching: Set()) 会阻止创建多余窗口。
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        if Self.verbose {
            os_log("\(self.label)Will Become Active")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appWillBecomeActive, object: self)
        }
    }

    // 收到远程通知
    // 如果改动由本设备发出：
    //  本设备：不会收到远程通知
    //  其他设备：会收到远程通知
    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        if Self.verbose {
            os_log("\(self.label)收到远程通知\n\(userInfo)")
        }
    }

    // MARK: - Open File / URL

    /// 处理通过 `open -a GitOK /path/to/repo`、拖拽文件夹到 Dock 图标、
    /// 以及 NSWorkspace.open([folderURL], withApplicationAt:) 触发的打开事件。
    /// 这是 macOS 冷启动时传递路径的主要方式，且不影响 SwiftUI WindowGroup 的窗口创建。
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.isFileURL {
                os_log("\(self.label)📂 Open file URL: \(url.path)")
                let resolvedPath = resolveGitRoot(from: url.path)
                setOpenPath(resolvedPath)
            } else {
                os_log("\(self.label)🔗 Open URL: \(url.absoluteString)")
                handleURL(url)
            }
        }
        activateMainWindow()
    }

    /// 处理通过 `open -a GitOK /path/to/repo` 或拖拽文件夹到 Dock 图标触发的打开事件
    /// 这是 macOS 的另一种文件打开方式，通常用于 Finder 拖拽或命令行 open 命令
    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        os_log("\(self.label)📂 Open file: \(filename)")

        let path = resolveGitRoot(from: filename)
        setOpenPath(path)
        activateMainWindow()
        return true
    }

    // MARK: - Private Helpers

    /// 激活应用主窗口并切换到其所在的 Space
    /// 当应用通过外部事件（open-document、URL Scheme 等）被激活时，
    /// macOS 不一定会自动切换到应用窗口所在的 Space（尤其是全屏模式）。
    ///
    /// GitHub Desktop 在每个入口都显式调用 window.focus() + window.show()：
    /// https://github.com/desktop/desktop/issues/973
    ///
    /// SwiftUI 的 WindowGroup 窗口标题为空，不能用 title 过滤。
    /// 冷启动时窗口可能还没创建，需要延迟重试等待窗口出现。
    private func activateMainWindow() {
        attemptActivate(retries: 5)
    }

    /// 尝试激活主窗口，支持延迟重试
    /// - Parameter retries: 剩余重试次数
    private func attemptActivate(retries: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            // SwiftUI WindowGroup 创建的主窗口使用 _NSWindowBackstage2 或类似内部类，
            // 不是 NSPanel，但某些内部窗口（如 TUINSWindow）不能成为 key window。
            // 使用 canBecomeKeyWindow 作为过滤条件，找到真正能成为 key window 的窗口。
            guard let window = NSApp.windows.first(where: {
                $0.canBecomeKey
            }) else {
                // 窗口还没创建（冷启动），延迟重试
                if retries > 0 {
                    attemptActivate(retries: retries - 1)
                }
                return
            }

            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    /// 将可能的路径或 URL 字符串规范化为文件系统路径
    /// 输入可能是：
    ///   - 已规范化的路径：/Users/colorfy/project
    ///   - file URL 字符串：file:///Users/colorfy/project
    ///   - URL 编码路径：/Users/colorfy/my%20project
    /// - Parameter raw: 原始字符串
    /// - Returns: 规范化后的文件系统路径
    private func normalizePath(_ raw: String) -> String {
        // 去除首尾空白和尾部斜杠
        var str = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasSuffix("/") { str = String(str.dropLast()) }

        // 如果是 file URL，先转换为路径
        if str.hasPrefix("file://") {
            if let url = URL(string: str) {
                return url.path
            }
            // 兜底：手动去掉 file:// 前缀
            let path = String(str.dropFirst("file://".count))
            return path.isEmpty ? raw : path
        }

        // 如果以 / 开头，可能已经是合法路径
        if str.hasPrefix("/") {
            // URL 解码（处理 %20 等转义）
            if let decoded = str.removingPercentEncoding {
                return decoded
            }
            return str
        }

        return str
    }

    /// 设置待打开的项目路径（在主线程）
    private func setOpenPath(_ path: String) {
        let normalized = normalizePath(path)
        os_log("\(self.label)📁 Set open path: \(normalized)")
        DispatchQueue.main.async { [weak self] in
            self?.pendingOpenPath = normalized
        }
    }

    /// 解析 URL Scheme 请求
    /// 支持格式：
    /// - `gitok://openRepo?path=/path/to/repo`
    /// - `gitok:///path/to/repo`
    private func handleURL(_ url: URL) {
        guard url.scheme == "gitok" else { return }

        let host = url.host?.lowercased()

        // gitok://openRepo?path=/xxx
        if host == "openrepo" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let path = components?.queryItems?.first(where: { $0.name == "path" })?.value,
               !path.isEmpty {
                setOpenPath(resolveGitRoot(from: path))
            }
            return
        }

        // gitok:///path/to/repo（路径直接写在 URL 中）
        let pathValue = url.path
        if !pathValue.isEmpty {
            setOpenPath(resolveGitRoot(from: pathValue))
            return
        }
    }

    /// 如果传入的是子目录，尝试向上查找 Git 仓库根目录
    /// - Parameter path: 原始路径（可能是 file URL 或文件路径）
    /// - Returns: Git 仓库根目录，如果找不到则返回原始路径
    private func resolveGitRoot(from path: String) -> String {
        let normalizedPath = normalizePath(path)
        var currentURL = URL(fileURLWithPath: normalizedPath)

        // 如果是文件，取其所在目录
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory),
           !isDirectory.boolValue {
            currentURL = currentURL.deletingLastPathComponent()
        }

        // 最多向上查找 10 层
        for _ in 0 ..< 10 {
            let gitPath = currentURL.appendingPathComponent(".git").path
            if FileManager.default.fileExists(atPath: gitPath) {
                return currentURL.path
            }
            let parent = currentURL.deletingLastPathComponent()
            if parent.path == currentURL.path { break } // 已到根目录
            currentURL = parent
        }

        return normalizedPath
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
