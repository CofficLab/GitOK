import Foundation
import KernelCore
import ProviderDocsView
import ProviderProjectReadme
import Testing
@testable import PluginProjectReadme

/// 覆盖 `ProjectReadmePlugin` 的完整生命周期：关于页贡献、Provider 注册与撤回，
/// 以及缺少 `DocsViewProviding` 时的优雅降级。
@Suite("PluginProjectReadme 生命周期")
@MainActor
struct ProjectReadmePluginLifecycleTests {

    @Test("onRegister 注册关于页条目")
    func onRegisterAddsAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = ProjectReadmePlugin()
        try plugin.onRegister(kernel: kernel)

        #expect(docs.aboutEntries.map(\.id) == [plugin.id])
        #expect(docs.aboutEntries.first?.name == plugin.metadata.name)
    }

    @Test("onUnregister 撤回关于页条目")
    func onUnregisterRemovesAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = ProjectReadmePlugin()
        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.count == 1)

        try plugin.onUnregister(kernel: kernel)

        #expect(docs.aboutEntries.isEmpty)
    }

    @Test("缺少 DocsViewProviding 时 onRegister 优雅降级")
    func onRegisterDegradesWithoutDocsProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectReadmePlugin()

        // 不注册任何 Provider，不应抛出异常。
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onBoot 注册 ProjectReadmeProviding")
    func onBootRegistersProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectReadmePlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.isProviderRegistered((any ProjectReadmeProviding).self))
        #expect(kernel.resolveProvider((any ProjectReadmeProviding).self) != nil)
    }

    @Test("onShutdown 撤回 ProjectReadmeProviding")
    func onShutdownUnregistersProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectReadmePlugin()

        try plugin.onBoot(kernel: kernel)
        #expect(kernel.isProviderRegistered((any ProjectReadmeProviding).self))

        try plugin.onShutdown(kernel: kernel)

        #expect(!kernel.isProviderRegistered((any ProjectReadmeProviding).self))
        #expect(kernel.resolveProvider((any ProjectReadmeProviding).self) == nil)
    }

    @Test("重复 onBoot 触发 Provider 重复注册错误")
    func repeatedBootFailsOnDuplicateProviderRegistration() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectReadmePlugin()

        try plugin.onBoot(kernel: kernel)

        // 第二次注册同一 Provider 应当抛出 KernelCoreError，而不是静默覆盖。
        #expect(throws: (any Error).self) {
            try plugin.onBoot(kernel: kernel)
        }
    }

    @Test("注册的 Provider 能为指定项目生成 README 视图")
    func registeredProviderBuildsReadmeView() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectReadmePlugin()
        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any ProjectReadmeProviding).self)
        let view = provider?.makeReadmeView(for: URL(fileURLWithPath: "/tmp/repo"))

        #expect(view != nil)
    }
}
