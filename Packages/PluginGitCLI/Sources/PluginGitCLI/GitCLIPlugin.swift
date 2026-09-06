import KernelCore
import ProviderDocsView
import ProviderGit

/// Git CLI 后端插件。
///
/// 插件只负责把 CLI 实现注册到稳定的 Git Provider；业务插件不直接依赖
/// 本插件，也不需要知道后端来自系统 git 还是 LibGit2。
@MainActor
public final class GitCLIPlugin: SuperPlugin {
    public let id = "com.coffic.gitok.plugin.git-cli"
    public let order = 1
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-cli",
        name: "Git CLI Backend",
        description: "Provides Git operations through the system git command.",
        category: .core,
        stage: .stable,
        policy: .required
    )

    private let backend = GitCLIBackend()

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitCLIAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        try register(in: kernel)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        unregister(from: kernel)
    }

    public func onEnable(kernel: KernelCoreContainer) async throws {
        try register(in: kernel)
    }

    public func onDisable(kernel: KernelCoreContainer) async throws {
        unregister(from: kernel)
    }

    private func register(in kernel: KernelCoreContainer) throws {
        guard let registry = kernel.resolveProvider((any GitBackendRegistryProviding).self) else {
            throw GitProviderError.noBackendAvailable
        }
        try registry.registerBackend(backend)
    }

    private func unregister(from kernel: KernelCoreContainer) {
        kernel.resolveProvider((any GitBackendRegistryProviding).self)?
            .unregisterBackend(id: backend.descriptor.id)
    }
}
