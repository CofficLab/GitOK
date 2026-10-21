import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderGit
import ProviderProjects
import ProviderSettingView
import SwiftUI
import Testing
@testable import PluginGitRepositorySettings

// MARK: - Tests

/// `GitRepositorySettingsPlugin` 的生命周期接线覆盖。
@Suite("GitRepositorySettingsPlugin 接线")
@MainActor
struct GitRepositorySettingsPluginWiringTests {

    private func makeKernel(
        withSettings: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        settings: DefaultSettingViewProviding,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        let docs = DefaultDocsViewProviding()
        if withSettings {
            try kernel.registerProvider((any SettingViewProviding).self, settings)
        }
        if withProjects {
            try kernel.registerProvider(
                (any ProjectProviding).self,
                GitRepositorySettingsDoubles.Projects()
            )
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, GitRepositorySettingsDoubles.Git())
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, settings, docs)
    }

    // MARK: - 守卫链

    @Test("缺少设置视图提供方时不注册入口项")
    func bootWithoutSettingView() throws {
        let (kernel, _, _) = try makeKernel(withSettings: false)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any SettingViewProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注册入口项")
    func bootWithoutProjects() throws {
        let (kernel, settings, _) = try makeKernel(withProjects: false)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("缺少 Git 提供方时不注册入口项")
    func bootWithoutGit() throws {
        let (kernel, settings, _) = try makeKernel(withGit: false)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    // MARK: - 入口项

    @Test("依赖齐备时注册 repository 设置入口")
    func bootRegistersSettingEntry() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.count == 1)
        let entry = try #require(settings.entries.first)
        #expect(entry.id == "repository")
        #expect(entry.systemImage == "folder.badge.gearshape")
        #expect(entry.order == 10)
        #expect(entry.title.isEmpty == false)
    }

    @Test("设置入口详情视图可以构造")
    func settingEntryDetailViewIsBuildable() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        let entry = try #require(settings.entries.first)
        let view = entry.makeDetailView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("onShutdown 撤回 repository 设置入口")
    func shutdownRemovesSettingEntry() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitRepositorySettingsPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("关于条目可以构造出视图")
    func aboutEntryBuildsView() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onRegister(kernel: kernel)

        let entry = try #require(docs.aboutEntries.first { $0.id == plugin.id })
        let view = entry.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = GitRepositorySettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("策略为 .disabled 的插件不会被 kernel.start 注册")
    func startViaKernelSkipsDisabledPolicy() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitRepositorySettingsPlugin()
        #expect(plugin.metadata.policy == .disabled)

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id) == false)
        #expect(settings.entries.isEmpty)
    }
}
