import GitCoreKit
import GitOKAppCore
import GitOKSupportKit
import OSLog
import SwiftData
import SwiftUI

/// GitOK 应用主入口
/// macOS 应用的主 App 结构体，负责应用的初始化和窗口管理
@main
struct GitOKApp: App, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚀"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// macOS 应用代理
    @NSApplicationDelegateAdaptor private var appDelegate: MacAgent

    init() {
        let start = Date()
        if Self.verbose {
            os_log("\(Self.t)🚀 Startup begin: GitOKApp.init")
        }

        // 初始化 libgit2
        GitRuntime.initialize()

        if Self.verbose {
            os_log("\(Self.t)✅ Startup end: GitOKApp.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    var body: some Scene {
        let _ = {
            if Self.verbose {
                os_log("\(Self.t)🚀 Startup phase: GitOKApp.body")
            }
        }()

        WindowGroup(id: AppBootstrap.mainWindowID) {
            ContentLayout()
                .inRootView()
                .settingsWindowOpener(appVM: RootContainer.shared.appVM)
                .environmentObject(appDelegate)
                .onReceive(appDelegate.$pendingOpenPath.compactMap { $0 }) { path in
                    // 通过 Combine 直接监听 appDelegate 的 @Published 属性变化
                    // 比 NotificationCenter 更可靠，不存在时序问题
                    OpenProjectHandler.shared.requestOpen(path: path)
                    // 清除 pending 状态，防止重复处理
                    appDelegate.pendingOpenPath = nil

                    // 确保窗口可见并激活（处理全屏 Space 切换和冷启动场景）
                    // 此时机窗口一定已创建，是最可靠的激活点
                    // 参考 GitHub Desktop: https://github.com/desktop/desktop/issues/973
                    DispatchQueue.main.async {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                }
        }
        .handlesExternalEvents(matching: Set()) // 阻止 WindowGroup 为外部事件创建新窗口
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(AppConfig.getContainer())
        .commands {
            DebugCommand()
            ConfigCommand()
            GitCommand()
            AppCommand()
            SettingsCommand()
        }

        Window(String(localized: "Settings"), id: AppBootstrap.settingsWindowID) {
            SettingsSceneContent()
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(
            width: AppBootstrap.defaultSettingsWindowSize.width,
            height: AppBootstrap.defaultSettingsWindowSize.height
        )
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
