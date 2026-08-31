import GitOKAppCore
import KitGitOKCore
import KernelCore
import OSLog
import ProviderProject
import SwiftData
import SwiftUI

/// Legacy GitOK service graph backed by the Lumi-compatible KernelCore.
///
/// New code should obtain a `KernelCoreContainer` from `KernelFactory` and
/// resolve typed providers from it. `RootContainer.shared` remains only as a
/// source-compatible bridge for previews and older integrations.
@MainActor
public final class RootContainer: ObservableObject {
    /// Plugin-agnostic composition inputs injected by the factory layer.
    public struct Composition {
        /// The compile-time plugin catalog to register.
        public var plugins: [any GitOKPlugin.Type] = []
        /// Plugin-owned runtime wiring that needs app-side providers.
        public var configurePluginRuntimes: ((GitOKProjectServicing) -> Void)?
        /// Chrome injected into the factory layout (e.g. sidebar add button).
        public var sidebarToolbarItem: AnyView?

        public init(
            plugins: [any GitOKPlugin.Type] = [],
            configurePluginRuntimes: ((GitOKProjectServicing) -> Void)? = nil,
            sidebarToolbarItem: AnyView? = nil
        ) {
            self.plugins = plugins
            self.configurePluginRuntimes = configurePluginRuntimes
            self.sidebarToolbarItem = sidebarToolbarItem
        }
    }

    private static var composition = Composition()

    /// Installs the composition before `shared` is first accessed.
    public static func configure(_ composition: Composition) {
        self.composition = composition
    }

    public static let shared = RootContainer(composition: composition, startPlugins: true)

    /// The single composition kernel shared by all views and commands.
    public let kernel: KernelCoreContainer

    public let repoManager: RepoManager
    public let appVM: AppVM
    public let pluginService: PluginService
    public let themeService: ThemeService
    public let gitCoreService: GitCoreService
    public let gitOKProjectService: GitOKProjectService
    public let navigationService: AppNavigationService
    public let pluginDependencies: GitOKPluginDependencies

    public let dataVM: DataVM
    public let projectVM: ProjectVM
    public let themeVM: AppThemeVM

    public init(composition: Composition, startPlugins: Bool = false) {
        os_log(.info, "RootContainer initialized with \(composition.plugins.count, privacy: .public) plugins")
        self.kernel = KernelCoreContainer()
        let container = AppConfig.getContainer()
        self.repoManager = RepoManager(modelContext: ModelContext(container))

        self.pluginDependencies = GitOKPluginDependencies()
        self.appVM = AppVM(repoManager: repoManager)
        self.pluginService = PluginService(
            pluginDependencies: pluginDependencies,
            pluginTypes: composition.plugins
        )
        self.themeVM = AppThemeVM(pluginProvider: pluginService)
        self.themeService = ThemeService(themeVM: themeVM)
        self.navigationService = AppNavigationService(appVM: appVM)

        var initialProject: Project?
        do {
            let projects = try repoManager.projectRepo.findAll(sortedBy: .ascending)
            self.dataVM = DataVM(projects: projects, repoManager: repoManager)

            let savedPath = repoManager.stateRepo.projectPath
            initialProject = projects.first(where: { $0.path == savedPath })
            if initialProject == nil, let firstProject = projects.first {
                initialProject = firstProject
                repoManager.stateRepo.setProjectPath(firstProject.path)
            }

            self.projectVM = ProjectVM(project: initialProject, repoManager: repoManager)
        } catch {
            os_log(.error, "RootContainer failed to load projects: \(error.localizedDescription)")
            self.dataVM = DataVM(projects: [], repoManager: repoManager)
            self.projectVM = ProjectVM(project: initialProject, repoManager: repoManager)
        }

        self.gitCoreService = GitCoreService(dataVM: dataVM, projectVM: projectVM)
        self.gitOKProjectService = GitOKProjectService(dataVM: dataVM, projectVM: projectVM)

        pluginDependencies.register(gitOKProjectService, for: GitOKProjectServicing.self)
        pluginDependencies.register(gitCoreService, for: GitOKRepositoryServicing.self)
        pluginDependencies.register(gitCoreService, for: GitOKActivityServicing.self)
        pluginDependencies.register(gitCoreService, for: GitOKGitCommandServicing.self)
        pluginDependencies.register(themeService, for: GitOKThemeServicing.self)
        pluginDependencies.register(navigationService, for: GitOKNavigationServicing.self)

        GitOKAppNavigationBridge.openSettings = { [navigationService] in
            navigationService.openSettings(tab: nil)
        }
        GitOKAppNavigationBridge.openPluginSettings = { [navigationService] in
            navigationService.openPluginSettings()
        }

        composition.configurePluginRuntimes?(gitOKProjectService)

        GitOKFactoryChrome.sidebarToolbarItem = composition.sidebarToolbarItem

        registerProviders()

        if startPlugins {
            try? kernel.start()
            do {
                try pluginService.startupPlugins()
            } catch {
                os_log(.fault, "Plugin startup failed: \(error.localizedDescription)")
            }
        }
    }

    /// Publishes the existing GitOK services through the Lumi-style typed
    /// Provider registry. The legacy `GitOKPluginDependencies` registry is
    /// intentionally populated as well so existing plugins keep working while
    /// they migrate to `KernelCoreContainer.resolveProvider`.
    private func registerProviders() {
        do {
            try kernel.registerProvider(RepoManager.self, repoManager)
            try kernel.registerProvider(AppVM.self, appVM)
            try kernel.registerProvider(PluginService.self, pluginService)
            try kernel.registerProvider(ThemeService.self, themeService)
            try kernel.registerProvider(GitCoreService.self, gitCoreService)
            try kernel.registerProvider(GitOKProjectService.self, gitOKProjectService)
            try kernel.registerProvider(AppNavigationService.self, navigationService)
            try kernel.registerProvider(GitOKPluginDependencies.self, pluginDependencies)
            try kernel.registerProvider(DataVM.self, dataVM)
            try kernel.registerProvider(ProjectVM.self, projectVM)
            try kernel.registerProvider(AppThemeVM.self, themeVM)
            try kernel.registerProvider((any GitOKProjectServicing).self, gitOKProjectService)
            try kernel.registerProvider((any GitOKRepositoryServicing).self, gitCoreService)
            try kernel.registerProvider((any GitOKActivityServicing).self, gitCoreService)
            try kernel.registerProvider((any GitOKGitCommandServicing).self, gitCoreService)
            try kernel.registerProvider((any GitOKThemeServicing).self, themeService)
            try kernel.registerProvider((any GitOKNavigationServicing).self, navigationService)
        } catch {
            os_log(.fault, "Kernel provider registration failed: %{public}@", error.localizedDescription)
        }
    }
}
