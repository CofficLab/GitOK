import GitCoreKit
import GitOKFactoryCore
import GitOKPluginRegistry
import SwiftUI

/// GitOK 应用主入口（Lumi `LumiApp` 等价物）：只负责窗口场景声明与
/// 渠道专属注入，插件组合与宿主引擎全部下沉到
/// `GitOKPluginRegistry/GitOKFactory` 与 `GitOKFactoryCore`。
@main
struct GitOKApp: App {
    /// macOS 应用代理
    @NSApplicationDelegateAdaptor private var appDelegate: MacAgent

    init() {
        // 初始化 libgit2
        GitRuntime.initialize()
    }

    var body: some Scene {
        WindowGroup(id: AppBootstrap.mainWindowID) {
            GitOKFactory.makeMainWindow()
                .environmentObject(appDelegate)
                .onReceive(appDelegate.$pendingOpenPath.compactMap { $0 }) { path in
                    // 通过 Combine 直接监听 appDelegate 的 @Published 属性变化
                    // 比 NotificationCenter 更可靠，不存在时序问题
                    OpenProjectHandler.shared.requestOpen(path: path)
                    appDelegate.pendingOpenPath = nil

                    // 确保窗口可见并激活（处理全屏 Space 切换和冷启动场景）
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
            GitOKFactory.makeCommands()
        }

        Window(String(localized: "Settings"), id: AppBootstrap.settingsWindowID) {
            GitOKFactory.makeSettingsWindow()
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(
            width: AppBootstrap.defaultSettingsWindowSize.width,
            height: AppBootstrap.defaultSettingsWindowSize.height
        )
    }
}
