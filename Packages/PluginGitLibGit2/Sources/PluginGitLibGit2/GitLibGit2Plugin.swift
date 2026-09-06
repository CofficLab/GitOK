import KernelCore
import LibGit2Swift
import ProviderDocsView
import ProviderGit

/// LibGit2 后端插件。
@MainActor
public final class GitLibGit2Plugin: SuperPlugin {
    public let id = "com.coffic.gitok.plugin.git-libgit2"
    public let order = 2
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-libgit2",
        name: "LibGit2 Backend",
        description: "Provides Git operations through LibGit2Swift.",
        category: .core,
        stage: .stable,
        policy: .required
    )

    private let backend = GitLibGit2Backend()

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitLibGit2AboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        LibGit2.initialize()
        do {
            try register(in: kernel)
        } catch {
            LibGit2.shutdown()
            throw error
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        unregister(from: kernel)
        LibGit2.shutdown()
    }

    public func onEnable(kernel: KernelCoreContainer) async throws {
        LibGit2.initialize()
        do {
            try register(in: kernel)
        } catch {
            LibGit2.shutdown()
            throw error
        }
    }

    public func onDisable(kernel: KernelCoreContainer) async throws {
        unregister(from: kernel)
        LibGit2.shutdown()
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
