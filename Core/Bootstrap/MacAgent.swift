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
        let verbose = false
        if verbose {
            os_log("\(self.label)Finish Lanunching")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Will Terminate")
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Did Become Active")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appDidBecomeActive, object: self)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Will Finish Launching")
        }

        // 注册 Apple Event 处理器，截获 open-document 事件
        // 这样可以防止 SwiftUI 的 WindowGroup 消费掉 open-file 事件
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleOpenDocuments(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        let verbose = false
        if verbose {
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
        let verbose = false
        if verbose {
            os_log("\(self.label)收到远程通知\n\(userInfo)")
        }
    }

    // MARK: - Open File / URL

    /// 处理 macOS Apple Event 的 open-document 事件
    /// 在 applicationWillFinishLaunching 中注册，优先于 SwiftUI 的 WindowGroup 处理
    @objc private func handleOpenDocuments(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let fileList = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else { return }

        // 提取文件路径列表
        var paths: [String] = []

        if fileList.descriptorType == typeAEList {
            for i in 1 ... fileList.numberOfItems {
                if let item = fileList.atIndex(i) {
                    if let path = extractPath(from: item) {
                        paths.append(path)
                    }
                }
            }
        } else {
            if let path = extractPath(from: fileList) {
                paths.append(path)
            }
        }

        for path in paths {
            os_log("\(self.label)📂 Apple Event open document: \(path)")
            let resolvedPath = resolveGitRoot(from: path)
            setOpenPath(resolvedPath)
        }
    }

    /// 从 Apple Event Descriptor 中提取文件路径
    /// macOS 传入的可能是 alias（typeAlias）、file URL（typeFileURL）或路径字符串
    private func extractPath(from descriptor: NSAppleEventDescriptor) -> String? {
        let descType = descriptor.descriptorType

        // 类型 1: file URL（typeFileURL = 'furl'）
        if descType == typeFileURL {
            return filePathFromDescriptorData(descriptor.data)
        }

        // 类型 2: alias — 用 Bookmark 解析
        if descType == typeAlias || descType == typeFSRef {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: descriptor.data,
                    options: .withoutUI,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                return url.path
            } catch {
                // Bookmark 解析失败，继续尝试其他方式
            }
        }

        // 类型 3: 路径字符串
        if let str = descriptor.stringValue {
            return str
        }

        // 类型 4: 尝试强制转为 file URL descriptor
        if let urlDesc = descriptor.coerce(toDescriptorType: typeFileURL) {
            return filePathFromDescriptorData(urlDesc.data)
        }

        return nil
    }

    /// 从 file URL descriptor 的 data 中提取文件系统路径
    /// descriptor.data 是 UTF-8 编码的 URL 字符串（如 "file:///Users/..."）
    /// 不能用 URL(dataRepresentation:) 因为它会错误解析 path
    private func filePathFromDescriptorData(_ data: Data) -> String? {
        guard let urlString = String(data: data, encoding: .utf8),
              let url = URL(string: urlString) else {
            return nil
        }
        return url.path
    }

    /// 处理通过 `open -a GitOK /path/to/repo` 或拖拽文件夹到 Dock 图标触发的打开事件
    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        os_log("\(self.label)📂 Open file: \(filename)")

        let path = resolveGitRoot(from: filename)
        setOpenPath(path)
        return true
    }

    /// 处理通过 URL Scheme（如 `gitok://openRepo?path=/xxx`）触发的打开事件
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            os_log("\(self.label)🔗 Open URL: \(url.absoluteString)")
            handleURL(url)
        }
    }

    // MARK: - Private Helpers

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
