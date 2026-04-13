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
                if let item = fileList.atIndex(i),
                   let url = URL(dataRepresentation: item.data, relativeTo: nil) {
                    paths.append(url.path)
                }
            }
        } else if let url = URL(dataRepresentation: fileList.data, relativeTo: nil) {
            paths.append(url.path)
        }

        for path in paths {
            os_log("\(self.label)📂 Apple Event open document: \(path)")
            let resolvedPath = resolveGitRoot(from: path)
            postOpenProject(path: resolvedPath)
        }
    }

    /// 处理通过 `open -a GitOK /path/to/repo` 或拖拽文件夹到 Dock 图标触发的打开事件
    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        os_log("\(self.label)📂 Open file: \(filename)")

        let path = resolveGitRoot(from: filename)
        postOpenProject(path: path)
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
                postOpenProject(path: resolveGitRoot(from: path))
            }
            return
        }

        // gitok:///path/to/repo（路径直接写在 URL 中）
        let pathValue = url.path
        if !pathValue.isEmpty {
            postOpenProject(path: resolveGitRoot(from: pathValue))
            return
        }
    }

    /// 如果传入的是子目录，尝试向上查找 Git 仓库根目录
    /// - Parameter path: 原始路径
    /// - Returns: Git 仓库根目录，如果找不到则返回原始路径
    private func resolveGitRoot(from path: String) -> String {
        var currentURL = URL(fileURLWithPath: path)

        // 如果是文件，取其所在目录
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
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

        return path
    }

    /// 发送打开项目的通知
    /// - Parameter path: 项目路径
    private func postOpenProject(path: String) {
        os_log("\(self.label)📁 Post open project: \(path)")

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .appOpenProject,
                object: self,
                userInfo: ["path": path]
            )
        }
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
