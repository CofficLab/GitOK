import Foundation
import KernelCore
import ProviderDocsView
import ProviderProjects
import ProviderStatusBar
import SwiftUI
import Testing
@testable import PluginLicense

/// `LicensePlugin` 的生命周期接线覆盖。
///
/// 插件在 `onBoot` 里向状态栏注入一个「License」项（视图体 `LicenseStatusIcon`
/// 读取当前项目目录下的 LICENSE 文件），在 `onShutdown` 撤回；
/// `onRegister` / `onUnregister` 负责「关于」条目的挂载与撤回。
@MainActor
@Suite("LicensePlugin lifecycle")
struct LicensePluginLifecycleTests {

    private func makeKernel(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        statusBar: DefaultStatusBarProviding,
        projects: LicenseTestProjectsProvider,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        let projects = LicenseTestProjectsProvider()
        let docs = DefaultDocsViewProviding()
        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, statusBar, projects, docs)
    }

    // MARK: - 守卫链

    @Test("缺少状态栏时不注入状态栏项")
    func bootWithoutStatusBar() throws {
        let (kernel, _, _, _) = try makeKernel(withStatusBar: false)
        let plugin = LicensePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注入状态栏项")
    func bootWithoutProjects() throws {
        let (kernel, statusBar, _, _) = try makeKernel(withProjects: false)
        let plugin = LicensePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注入一个 leading 状态栏项")
    func bootRegistersStatusBarItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = LicensePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)
        let item = statusBar.statusBarItems.first
        #expect(item?.id == LicensePlugin.itemID)
        #expect(item?.placement == .leading)
        #expect(item?.order == 22)
    }

    @Test("onShutdown 撤回状态栏项")
    func shutdownRemovesStatusBarItem() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = LicensePlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("状态栏项的视图可以被构造")
    func statusBarItemViewCanBeConstructed() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = LicensePlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let item = try #require(statusBar.statusBarItems.first)
        let view = item.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = LicensePlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = LicensePlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = LicensePlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("策略为 .disabled 的插件不会被 kernel.start 注册")
    func startViaKernelSkipsDisabledPolicy() throws {
        let (kernel, statusBar, _, _) = try makeKernel()
        let plugin = LicensePlugin()
        #expect(plugin.metadata.policy == .disabled)

        try kernel.start(plugins: [plugin])

        // KernelCore 会彻底排除策略为 .disabled 的插件：不注册、不启动。
        #expect(kernel.isPluginRegistered(id: plugin.id) == false)
        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 本地化

    @Test("本地化助手可按 key 取值")
    func localizationReturnsValue() {
        let value = LicenseLocalization.string("License", bundle: .module)
        #expect(!value.isEmpty)
    }
}
