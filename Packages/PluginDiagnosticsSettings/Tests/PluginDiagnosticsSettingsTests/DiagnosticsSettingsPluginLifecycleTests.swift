import Foundation
import KernelCore
import ProviderSettingView
import SwiftUI
import Testing

@testable import PluginDiagnosticsSettings

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

// MARK: - Tests

@Suite("DiagnosticsSettingsPlugin 生命周期")
@MainActor
struct DiagnosticsSettingsPluginLifecycleTests {

    @Test("插件标识与元数据稳定")
    func identity() {
        let plugin = DiagnosticsSettingsPlugin()

        #expect(plugin.id == "com.coffic.gitok.plugin.diagnostics-settings")
        #expect(plugin.order == 47)
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.metadata.name == "Diagnostics")
        #expect(plugin.metadata.category == .system)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.metadata.policy == .disabled)
    }

    @Test("缺少 SettingViewProviding 时 onBoot 安全降级")
    func bootWithoutSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = DiagnosticsSettingsPlugin()

        // 无任何 provider 注册时应直接返回，不抛错
        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any SettingViewProviding).self) == nil)
    }

    @Test("依赖齐备时注册诊断入口项")
    func bootRegistersEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onBoot(kernel: kernel)

        let entry = try #require(settings.entries.first)
        #expect(entry.id == "diagnostics")
        #expect(entry.systemImage == "stethoscope")
        #expect(entry.order == 60)
        // 标题经本地化，随系统语言变化；只断言非空
        #expect(entry.title.isEmpty == false)
        #expect(settings.entries.count == 1)
    }

    @Test("onShutdown 按 id 撤回入口项")
    func shutdownRemovesEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 在从未 boot 时也安全")
    func shutdownWithoutBoot() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.isEmpty)
    }

    @Test("onShutdown 在缺少 SettingViewProviding 时安全")
    func shutdownWithoutSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("重复 boot 不产生重复入口项")
    func repeatedBootDoesNotDuplicate() throws {
        let kernel = KernelCoreContainer()
        let settings = MockSettingViewProvider()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

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
            SettingEntryItem(id: "other", title: "Other", systemImage: "gear") { EmptyView() }
        ]
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(settings.entries.map(\.id) == ["other"])
    }

    @Test("onRegister / onUnregister 在无 DocsView 时安全降级")
    func registerWithoutDocs() throws {
        let kernel = KernelCoreContainer()
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }
}
