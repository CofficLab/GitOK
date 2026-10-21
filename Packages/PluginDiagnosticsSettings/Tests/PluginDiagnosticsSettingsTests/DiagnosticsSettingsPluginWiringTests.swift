import Foundation
import KernelCore
import ProviderDocsView
import ProviderSettingView
import SwiftUI
import Testing
@testable import PluginDiagnosticsSettings

/// `DiagnosticsSettingsPlugin` 的「关于」条目与内核启动接线覆盖。
@Suite("DiagnosticsSettingsPlugin 接线")
@MainActor
struct DiagnosticsSettingsPluginWiringTests {

    @Test("设置入口的详情视图可以被构造")
    func settingEntryDetailViewCanBeConstructed() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let entry = try #require(settings.entries.first { $0.id == "diagnostics" })
        let detail = entry.makeDetailView()
        #expect(type(of: detail) == AnyView.self)
    }

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = DiagnosticsSettingsPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("策略为 .disabled 的插件不会被 kernel.start 注册")
    func startViaKernelSkipsDisabledPolicy() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let plugin = DiagnosticsSettingsPlugin()
        #expect(plugin.metadata.policy == .disabled)

        try kernel.start(plugins: [plugin])

        // KernelCore 会彻底排除策略为 .disabled 的插件：不注册、不启动。
        #expect(kernel.isPluginRegistered(id: plugin.id) == false)
        #expect(settings.entries.isEmpty)
    }
}
