import KitGitCore
import FactoryCore
import FactoryGitOK
import KitGitOKUpdate
import KernelCore
import SwiftUI

/// GitOK 应用主入口（Lumi `LumiApp` 等价物）：只负责窗口场景声明与
/// 渠道专属注入，插件组合与宿主引擎全部下沉到
/// `FactoryGitOK/GitOKFactory` 与 `FactoryCore`。
///
/// 渠道专属注入（对应 Lumi 在 LumiApp 层注入 AppUpdatePlugin）：
/// - Sparkle 自动更新（`KitGitOKUpdate`）通过启动钩子接入，
///   上架 Mac App Store 的变体可不链接它。
@main
struct GitOKApp: App {
    /// macOS 应用代理
    @NSApplicationDelegateAdaptor private var appDelegate: MacAgent

    /// Main and settings scenes share this single composition kernel.
    private let kernel: KernelCoreContainer
    private let mainView: AnyView
    private let settingsView: AnyView

    init() {
        GitRuntime.initialize()

        do {
            let assembledKernel = try GitOKFactory.makeKernel()
            kernel = assembledKernel
            mainView = (try? GitOKFactory.makeMainWindow(kernel: assembledKernel))
                ?? AnyView(Text("Failed to assemble main view"))
            settingsView = (try? GitOKFactory.makeSettingsWindow(kernel: assembledKernel))
                ?? AnyView(Text("Failed to assemble settings view"))
        } catch {
            kernel = KernelCoreContainer()
            mainView = AnyView(Text("Failed to assemble main view: \(error.localizedDescription)"))
            settingsView = AnyView(Text("Failed to assemble settings view: \(error.localizedDescription)"))
        }

        // 同步初始化 Sparkle updater（确保菜单栏"检查更新"可用），
        // 并异步检测 feed URL fallback。
        GitOKFactoryChrome.launchHooks.append {
            _ = UpdateManager.shared
            Task {
                await UpdateManager.shared.setupFeedURLIfNeeded()
            }
        }
    }

    var body: some Scene {
        WindowGroup(id: AppBootstrap.mainWindowID) {
            mainView
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
            GitOKFactory.makeCommands(kernel: kernel)
            UpdateCommand()
        }

        Window(String(localized: "Settings"), id: AppBootstrap.settingsWindowID) {
            settingsView
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(
            width: AppBootstrap.defaultSettingsWindowSize.width,
            height: AppBootstrap.defaultSettingsWindowSize.height
        )
    }
}
