import AppKit
import KitGitOKUpdate
import LumiFactory
import SwiftUI

@main
struct GitOKApp: App {
    /// 共享应用代理：`gitok://` URL / 文件打开事件排队补发、设置深链、
    /// Dock 重开主窗口，全部由 HostManifest 解释。
    @NSApplicationDelegateAdaptor(HostAppDelegate.self) private var appDelegate
    @StateObject private var bootstrapper: KernelBootstrapper

    init() {
        // GitOK 是单窗口应用：关闭 macOS 的自动窗口标签页，
        // 否则系统会在「显示」菜单里注入「显示标签页栏 / 合并所有窗口」，
        // 并允许 ⌘T 把窗口合并成原生标签页。
        // 必须早于任何窗口创建，因此放在 App init 中设置。
        NSWindow.allowsAutomaticWindowTabbing = false

        HostAppDelegate.prepareForLaunch()
        AppUpdateBootstrap.start()

        let bootstrapper = KernelBootstrapper(
            manifest: GitOKHostManifest.make {
                UpdateService.shared.checkForUpdates()
            }
        )
        _bootstrapper = StateObject(wrappedValue: bootstrapper)
        appDelegate.bootstrapper = bootstrapper
    }

    var body: some Scene {
        // Window（而非 WindowGroup）+ 无标题栏 + 统一工具栏 + 设置窗 + 命令，
        // 全部由共享壳提供；AX 就绪标记走 1×1 overlay（见 GitOKHostManifest）。
        HostMacScenes(bootstrapper: bootstrapper)
    }
}