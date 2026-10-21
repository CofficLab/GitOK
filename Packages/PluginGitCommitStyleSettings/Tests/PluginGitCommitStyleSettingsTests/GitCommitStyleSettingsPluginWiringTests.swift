import Foundation
import KernelCore
import ProviderDocsView
import ProviderSettingView
import SwiftUI
import Testing
@testable import PluginGitCommitStyleSettings

/// 记录设置入口写入的最小 `SettingViewProviding` 替身。
@MainActor
private final class CommitStyleSettingViewProvider: SettingViewProviding {
    var entries: [SettingEntryItem] = []
    var selectedEntryID: String?

    func selectEntry(id: String?) {
        selectedEntryID = id
    }

    func registerEntries(_ entries: [SettingEntryItem]) {
        self.entries = entries
    }

    func addEntries(_ entries: [SettingEntryItem]) {
        for entry in entries where !self.entries.contains(where: { $0.id == entry.id }) {
            self.entries.append(entry)
        }
    }

    func removeEntries(ids: Set<String>) {
        entries.removeAll { ids.contains($0.id) }
    }

    func makeSettingView() -> AnyView { AnyView(EmptyView()) }
}

/// `GitCommitStyleSettingsPlugin` 的接线覆盖。
///
/// 插件在 `onBoot` 里向设置窗口追加「Commit Style」入口，`onShutdown` 撤回；
/// `onRegister` / `onUnregister` 负责「关于」条目的挂载与撤回。
@Suite("GitCommitStyleSettingsPlugin 接线")
@MainActor
struct GitCommitStyleSettingsPluginWiringTests {

    private func makeKernel(
        withSettingView: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        settings: CommitStyleSettingViewProvider,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let settings = CommitStyleSettingViewProvider()
        let docs = DefaultDocsViewProviding()
        if withSettingView {
            try kernel.registerProvider((any SettingViewProviding).self, settings)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, settings, docs)
    }

    // MARK: - 守卫

    @Test("缺少 SettingViewProviding 时安全降级")
    func bootWithoutSettingView() throws {
        let (kernel, _, _) = try makeKernel(withSettingView: false)
        let plugin = GitCommitStyleSettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any SettingViewProviding).self) == nil)
    }

    // MARK: - 入口项

    @Test("依赖齐备时注册 commitStyle 设置入口")
    func bootRegistersSettingEntry() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitCommitStyleSettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.count == 1)
        let entry = try #require(settings.entries.first)
        #expect(entry.id == "commitStyle")
        #expect(entry.systemImage == "text.alignleft")
        #expect(entry.order == 30)
        #expect(entry.title.isEmpty == false)
    }

    @Test("onShutdown 撤回 commitStyle 入口")
    func shutdownRemovesSettingEntry() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("设置入口的详情视图可以被构造")
    func settingEntryDetailViewCanBeConstructed() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let entry = try #require(settings.entries.first)
        let detail = entry.makeDetailView()
        #expect(type(of: detail) == AnyView.self)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitCommitStyleSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 只撤回本插件贡献的入口项")
    func shutdownKeepsForeignEntries() throws {
        let (kernel, settings, _) = try makeKernel()
        settings.entries = [
            SettingEntryItem(id: "other", title: "Other", systemImage: "gear") { EmptyView() }
        ]
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["other"])
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitCommitStyleSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = GitCommitStyleSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并注册设置入口")
    func startViaKernel() throws {
        let (kernel, settings, _) = try makeKernel()
        let plugin = GitCommitStyleSettingsPlugin()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(settings.entries.count == 1)
        try kernel.stop()
    }
}
