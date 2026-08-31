import GitOKAppCore
import KitGitOKCore
import KernelCore
import ProviderProject

/// Factory boundary for the host's typed Provider graph.
@MainActor
public protocol ProviderFactory {
    /// Produces the plugin host that publishes plugin contributions.
    func makePluginProvider(
        kernel: KernelCoreContainer,
        dependencies: GitOKPluginDependencies,
        pluginTypes: [any GitOKPlugin.Type]
    ) -> PluginService

    /// Produces the project provider consumed by plugins and the app shell.
    func makeProjectProvider(
        dataVM: DataVM,
        projectVM: ProjectVM
    ) -> any GitOKProjectServicing

    /// Produces the Git/repository provider used by commands and plugins.
    func makeGitProvider(
        dataVM: DataVM,
        projectVM: ProjectVM
    ) -> any GitOKRepositoryServicing & GitOKActivityServicing & GitOKGitCommandServicing

    /// Produces the theme provider backed by the app's theme state.
    func makeThemeProvider(themeVM: AppThemeVM) -> any GitOKThemeServicing

    /// Produces the navigation provider backed by the app state.
    func makeNavigationProvider(appVM: AppVM) -> any GitOKNavigationServicing

    /// Assembles providers into the kernel created by `KernelFactory`.
    func makeRootContainer(
        kernel: KernelCoreContainer,
        composition: RootContainer.Composition
    ) throws -> RootContainer

    /// Compatibility entry point for previews and older integrations.
    func makeRootContainer(composition: RootContainer.Composition) throws -> RootContainer
}

@MainActor
public struct DefaultProviderFactory: ProviderFactory {
    public init() {}

    public func makePluginProvider(
        kernel: KernelCoreContainer,
        dependencies: GitOKPluginDependencies,
        pluginTypes: [any GitOKPlugin.Type]
    ) -> PluginService {
        PluginService(
            kernel: kernel,
            pluginDependencies: dependencies,
            pluginTypes: pluginTypes
        )
    }

    public func makeProjectProvider(
        dataVM: DataVM,
        projectVM: ProjectVM
    ) -> any GitOKProjectServicing {
        GitOKProjectService(dataVM: dataVM, projectVM: projectVM)
    }

    public func makeGitProvider(
        dataVM: DataVM,
        projectVM: ProjectVM
    ) -> any GitOKRepositoryServicing & GitOKActivityServicing & GitOKGitCommandServicing {
        GitCoreService(dataVM: dataVM, projectVM: projectVM)
    }

    public func makeThemeProvider(themeVM: AppThemeVM) -> any GitOKThemeServicing {
        ThemeService(themeVM: themeVM)
    }

    public func makeNavigationProvider(appVM: AppVM) -> any GitOKNavigationServicing {
        AppNavigationService(appVM: appVM)
    }

    public func makeRootContainer(composition: RootContainer.Composition) throws -> RootContainer {
        RootContainer(composition: composition, providerFactory: self)
    }

    public func makeRootContainer(
        kernel: KernelCoreContainer,
        composition: RootContainer.Composition
    ) throws -> RootContainer {
        RootContainer(composition: composition, providerFactory: self, kernel: kernel)
    }
}
