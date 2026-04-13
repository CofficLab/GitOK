import LibGit2Swift
import MagicKit
import Sparkle
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

    /// Sparkle 更新控制器
    private let updaterController: SPUStandardUpdaterController

    init() {
        // 初始化 libgit2
        LibGit2.initialize()
        
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentLayout()
                .inRootView()
                .environmentObject(appDelegate)
                .onReceive(appDelegate.$pendingOpenPath.compactMap { $0 }) { path in
                    // 通过 Combine 直接监听 appDelegate 的 @Published 属性变化
                    // 比 NotificationCenter 更可靠，不存在时序问题
                    OpenProjectHandler.shared.requestOpen(path: path)
                    // 清除 pending 状态，防止重复处理
                    appDelegate.pendingOpenPath = nil
                }
        }
        .handlesExternalEvents(matching: Set()) // 阻止 WindowGroup 为外部事件创建新窗口
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(AppConfig.getContainer())
        .commands(content: {
            DebugCommand()
            ConfigCommand()
            AppCommand()

            CommandGroup(after: .appInfo) {
                UpdaterView(updater: updaterController.updater)
            }
        })
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
