import GitOKAppCore
import GitOKCoreKit
import OSLog
import ProjectKit
import SwiftData
import SwiftUI

/// Composition root of the app (Lumi factory-host equivalent).
///
/// The container itself is plugin-agnostic: the concrete plugin catalog and
/// plugin-owned bootstrap hooks are injected by the factory composition layer
/// (`GitOKFactory` in `GitOKPluginRegistry`) via ``configure(_:)`` before the
/// singleton is first touched.
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

    public static let shared = RootContainer(composition: composition)

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

    private init(composition: Composition) {
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

        do {
            try pluginService.startupPlugins()
        } catch {
            os_log(.fault, "Plugin startup failed: \(error.localizedDescription)")
        }
    }
}
