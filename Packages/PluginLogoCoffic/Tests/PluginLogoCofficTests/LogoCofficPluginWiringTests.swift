import Foundation
import KernelCore
import ProviderDocsView
import ProviderLogo
import SwiftUI
import Testing
@testable import PluginLogoCoffic

/// `LogoCofficPlugin` 的生命周期接线覆盖。
@Suite("LogoCofficPlugin 接线")
@MainActor
struct LogoCofficPluginWiringTests {

    private func makeKernel(
        withLogo: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        logo: DefaultLogoProviding,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let logo = DefaultLogoProviding()
        let docs = DefaultDocsViewProviding()
        if withLogo {
            try kernel.registerProvider((any LogoProviding).self, logo)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, logo, docs)
    }

    // MARK: - 元数据

    @Test("插件元数据符合设计类插件规范")
    func pluginMetadata() {
        let plugin = LogoCofficPlugin()
        #expect(plugin.id == "com.lumi.plugin.logo-coffic")
        #expect(plugin.order == 100)
        #expect(plugin.metadata.category == .design)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.metadata.policy == .disabled)
    }

    // MARK: - 守卫链

    @Test("缺少 Logo 提供方时不注册 Logo 项")
    func bootWithoutLogoProvider() throws {
        let (kernel, _, _) = try makeKernel(withLogo: false)
        let plugin = LogoCofficPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any LogoProviding).self) == nil)
    }

    @Test("依赖齐备时注册 Coffic Logo 项")
    func bootRegistersLogoItem() throws {
        let (kernel, logo, _) = try makeKernel()
        let plugin = LogoCofficPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(logo.allLogoItems.count == 1)
        let item = try #require(logo.allLogoItems.first)
        #expect(item.id == "com.lumi.plugin.logo-coffic")
        #expect(item.order == 100)
    }

    @Test("Logo 项可以构造出视图")
    func logoItemBuildsView() throws {
        let (kernel, logo, _) = try makeKernel()
        let plugin = LogoCofficPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(logo.allLogoItems.first)
        let view = item.makeView(.statusBar)
        #expect(type(of: view) == AnyView.self)
    }

    @Test("onShutdown 注销 Coffic Logo 项")
    func shutdownUnregistersLogoItem() throws {
        let (kernel, logo, _) = try makeKernel()
        let plugin = LogoCofficPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(logo.allLogoItems.isEmpty)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, logo, _) = try makeKernel()
        let plugin = LogoCofficPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(logo.allLogoItems.isEmpty)
    }

    // MARK: - onRegister / onUnregister

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = LogoCofficPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("关于条目可以构造出视图")
    func aboutEntryBuildsView() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = LogoCofficPlugin()

        try plugin.onRegister(kernel: kernel)

        let entry = try #require(docs.aboutEntries.first { $0.id == plugin.id })
        let view = entry.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = LogoCofficPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    @Test("策略为 .disabled 的插件不会被 kernel.start 注册")
    func startViaKernelSkipsDisabledPolicy() throws {
        let (kernel, logo, _) = try makeKernel()
        let plugin = LogoCofficPlugin()
        #expect(plugin.metadata.policy == .disabled)

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id) == false)
        #expect(logo.allLogoItems.isEmpty)
    }
}
