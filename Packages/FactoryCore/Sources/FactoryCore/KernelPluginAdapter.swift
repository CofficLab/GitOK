import KitGitOKCore
import KernelCore

/// Bridges GitOK's existing static plugin runtime into the generic Lumi-style
/// Kernel lifecycle. The adapter is intentionally one host plugin: the legacy
/// runtime still owns GitOK contribution queries and enable-state persistence.
@MainActor
final class GitOKPluginKernelAdapter: KernelPlugin {
    let id = "com.coffic.gitok.plugin-runtime"
    let order = 0
    private let pluginService: PluginService

    init(pluginService: PluginService) {
        self.pluginService = pluginService
    }

    func onBoot(kernel: KernelCoreContainer) throws {
        try pluginService.startupPlugins()
    }
}
