import Foundation
import KernelCore
import ProviderSettingView
import SwiftUI
import Testing
@testable import PluginAboutSettings

// MARK: - Test Doubles

/// 记录设置入口写入的最小 `SettingViewProviding` 替身。
@MainActor
private final class MockSettingViewProvider: SettingViewProviding {
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

// MARK: - 元数据

@Suite("PluginAboutSettings")
@MainActor
struct PluginAboutSettingsTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = AboutSettingsPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.about-settings")
        #expect(plugin.metadata.category == .system)
        #expect(plugin.metadata.policy == .disabled)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.order == 44)
        #expect(plugin.metadata.id == "com.coffic.gitok.plugin.about-settings")
        #expect(plugin.metadata.name == "About")
    }

    @Test("localization lookup returns a non-empty string for known key")
    func localizationLookup() {
        let result = AboutSettingsLocalization.string("About", bundle: .module)
        // Either the catalog resolves it or it falls back to the key itself.
        #expect(result.isEmpty == false)
    }
}

// MARK: - 生命周期

@Suite("AboutSettingsPlugin 生命周期")
@MainActor
struct AboutSettingsPluginLifecycleTests {

    @Test("缺少 SettingViewProviding 时 onBoot 安全降级")
    func bootWithoutSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = AboutSettingsPlugin()

        // 无任何 provider 注册时应直接返回，不抛错
        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any SettingViewProviding).self) == nil)
    }

    @Test("依赖齐备时注册 about 入口项")
    func bootRegistersEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        let entry = try #require(settings.entries.first)
        #expect(entry.id == "about")
        #expect(entry.systemImage == "info.circle")
        #expect(entry.order == 90)
        // 标题经本地化，随系统语言变化；只断言非空
        #expect(entry.title.isEmpty == false)
        #expect(settings.entries.count == 1)
    }

    @Test("onShutdown 按 id 撤回入口项")
    func shutdownRemovesEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 在从未 boot 时也安全")
    func shutdownWithoutBoot() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 在缺少 SettingViewProviding 时安全")
    func shutdownWithoutSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = AboutSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("重复 boot 不产生重复入口项")
    func repeatedBootDoesNotDuplicate() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 只撤回本插件贡献的入口项")
    func shutdownKeepsForeignEntries() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        settings.entries = [
            SettingEntryItem(id: "diagnostics", title: "Diagnostics", systemImage: "stethoscope") {
                EmptyView()
            }
        ]
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["diagnostics"])
    }

    @Test("about 入口与 diagnostics 入口共存且互不覆盖")
    func coexistsWithDiagnosticsEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        settings.entries = [
            SettingEntryItem(id: "diagnostics", title: "Diagnostics", systemImage: "stethoscope") {
                EmptyView()
            }
        ]
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = AboutSettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["diagnostics", "about"])

        try plugin.onShutdown(kernel: kernel)
        #expect(settings.entries.map(\.id) == ["diagnostics"])
    }
}
