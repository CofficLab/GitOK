import FactoryGitOK
import KernelCore
import ProviderSettingView
import SwiftUI

@main
struct GitOKApp: App {
    private let kernel: KernelCoreContainer
    private let mainView: AnyView
    private let settingsView: AnyView
    @Environment(\.openWindow) private var openWindow

    init() {
        if let assembledKernel = try? FactoryGitOK.makeKernel() {
            kernel = assembledKernel
            mainView = (try? FactoryGitOK.makeMainView(kernel: assembledKernel))
                ?? AnyView(Text("Failed to assemble main view"))
            settingsView = (try? FactoryGitOK.makeSettingsView(kernel: assembledKernel))
                ?? AnyView(Text("Failed to assemble settings view"))
        } else {
            let fallbackKernel = KernelCoreContainer()
            kernel = fallbackKernel
            mainView = AnyView(Text("Failed to assemble main view"))
            settingsView = AnyView(Text("Failed to assemble settings view"))
        }
    }

    var body: some Scene {
        WindowGroup("GitOK", id: "gitok.main") {
            mainView
                .onReceive(NotificationCenter.default.publisher(
                    for: SettingViewNavigation.openSettingsNotification
                )) { notification in
                    if let settings = kernel.resolveProvider((any SettingViewProviding).self),
                       let entryID = notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String,
                       settings.entries.contains(where: { $0.id == entryID }) {
                        settings.selectEntry(id: entryID)
                    }
                    openWindow(id: "gitok.settings")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 760)
        .commands {
            AppCommands(kernel: kernel)
        }

        // 与 Lumi 使用相同的普通 Window Scene，避免 macOS Settings 容器
        // 额外注入边距/安全区域，导致共享设置视图被裁切。
        Window("设置", id: "gitok.settings") {
            settingsView
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1000, height: 600)
    }
}
