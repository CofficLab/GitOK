import Foundation
import KernelCore
import ProviderDocsView
import ProviderSettingView
import SwiftUI
import Testing
@testable import PluginGitNetworkSettings

/// 覆盖 `GitNetworkSettingsPlugin` 的完整生命周期：关于页贡献、设置入口注入与撤回，
/// 以及缺少 `SettingViewProviding` / `DocsViewProviding` 时的优雅降级。
@Suite("PluginGitNetworkSettings 生命周期")
@MainActor
struct GitNetworkSettingsPluginLifecycleTests {

    @Test("onRegister 注册关于页条目")
    func onRegisterAddsAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onRegister(kernel: kernel)

        #expect(docs.aboutEntries.map(\.id) == [plugin.id])
        #expect(docs.aboutEntries.first?.name == plugin.metadata.name)
    }

    @Test("onUnregister 撤回关于页条目")
    func onUnregisterRemovesAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.count == 1)

        try plugin.onUnregister(kernel: kernel)

        #expect(docs.aboutEntries.isEmpty)
    }

    @Test("缺少 DocsViewProviding 时生命周期不抛异常")
    func lifecycleDegradesWithoutDocsProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitNetworkSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onBoot 注入 Network 设置入口")
    func onBootAddsSettingEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["network"])
        #expect(settings.entries.first?.order == 40)
        #expect(settings.entries.first?.systemImage == "network")
    }

    @Test("onBoot 保留其它插件已注入的设置入口")
    func onBootKeepsExistingEntries() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        settings.registerEntries([
            SettingEntryItem(id: "other", title: "Other", systemImage: "gear") { EmptyView() },
        ])

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.map(\.id).sorted() == ["network", "other"])
    }

    @Test("缺少 SettingViewProviding 时 onBoot 优雅降级")
    func onBootDegradesWithoutSettingProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitNetworkSettingsPlugin()

        // 未注册 SettingViewProviding：不应抛出异常。
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onShutdown 按 id 撤回设置入口")
    func onShutdownRemovesSettingEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(settings.entries.count == 1)

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 只撤回自身入口")
    func onShutdownRemovesOnlyOwnEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        settings.registerEntries([
            SettingEntryItem(id: "other", title: "Other", systemImage: "gear") { EmptyView() },
        ])

        let plugin = GitNetworkSettingsPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["other"])
    }

    @Test("缺少 SettingViewProviding 时 onShutdown 不抛异常")
    func onShutdownDegradesWithoutSettingProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitNetworkSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)
    }
}
