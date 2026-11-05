import AppKit
import FactoryGitOK
import KernelCore
import Foundation
import os

/// GitOK 的应用代理：接收 macOS Launch Services 投递的 URL / 文件打开事件。
///
/// CLI 脚本 `gitok <path>` 会把目标目录编码进 `gitok://open?path=...`，
/// 由 Launch Services 路由到本 App。代理解析出目标目录后**直接**调用
/// `FactoryGitOK.openExternalPath(path:kernel:)`，把目录加入项目列表并
/// 切换为当前项目。
///
/// 为什么不走「SwiftUI 视图订阅 + 通知」的路子：
/// Launch Services 投递 URL 的时机与主窗口建立 SwiftUI 订阅的时机相互独立，
/// 事件可能在订阅建立之前到达，也可能在视图更新期间到达；
/// 在代理里直接调用内核可以让每条请求都被处理，且不依赖任何视图生命周期。
@MainActor
final class GitOKAppDelegate: NSObject, NSApplicationDelegate {
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok",
        category: "AppDelegate"
    )

    /// 是否输出详细日志。
    nonisolated static let verbose = false

    /// 内核容器引用。
    ///
    /// 由宿主在 `App.init` 装配内核后注入；`nil` 表示内核尚未就绪，
    /// 此时到达的请求会被暂存在 `pendingOpenPaths` 里等待消费。
    private(set) var kernel: KernelCoreContainer?

    /// 内核就绪前收到的路径请求。
    private var pendingOpenPaths: [String] = []

    // MARK: - Kernel Wiring

    /// 绑定内核并处理此前暂存的请求。
    ///
    /// 宿主在 `App.init` 装配内核后调用。内核尚未就绪时到达的 URL 事件
    /// （App 冷启动时很常见）会先入队，这里一次性排空。
    func attach(kernel: KernelCoreContainer) {
        self.kernel = kernel
        drainPendingPaths()
    }

    // MARK: - NSApplicationDelegate

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard let path = Self.resolveOpenPath(from: url) else {
                Self.logger.warning("Ignoring unsupported URL: \(url.absoluteString, privacy: .public)")
                continue
            }
            enqueue(path)
        }
        if !pendingOpenPaths.isEmpty {
            activateMainWindow()
        }
    }

    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        enqueue((filename as NSString).standardizingPath)
        activateMainWindow()
        return true
    }

    // MARK: - Request Handling

    /// 记录一条路径请求；内核就绪时立即处理。
    private func enqueue(_ path: String) {
        if Self.verbose {
            Self.logger.info("Received directory open request: \(path, privacy: .public)")
        }
        pendingOpenPaths.append(path)
        drainPendingPaths()
    }

    /// 逐条处理排队的路径请求。
    private func drainPendingPaths() {
        guard let kernel else { return }
        while !pendingOpenPaths.isEmpty {
            let path = pendingOpenPaths.removeFirst()
            let opened = FactoryGitOK.openExternalPath(path, kernel: kernel)
            if !opened {
                Self.logger.error("Failed to open directory: \(path, privacy: .public)")
            }
        }
    }

    // MARK: - Path Resolution

    /// 从 URL 中解析出要打开的目录绝对路径。
    ///
    /// 委托给 `ExternalOpenRequest`（装配层），便于单元测试覆盖
    /// URL 编解码的一致性。
    static func resolveOpenPath(from url: URL) -> String? {
        ExternalOpenRequest.resolveDirectory(from: url)
    }

    // MARK: - Window Activation

    /// 把主窗口唤到前台。
    ///
    /// CLI 触发的场景下 GitOK 可能已在后台运行，必须显式激活，
    /// 否则用户看不到「已打开」的结果。
    private func activateMainWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows
                .first { $0.identifier?.rawValue == Self.mainWindowIdentifier }
                .map { $0.makeKeyAndOrderFront(nil) }
        }
    }

    /// 主窗口标识（与 `GitOKApp` 的 `Window(id:)` 保持一致）。
    static let mainWindowIdentifier = "gitok.main"
}
