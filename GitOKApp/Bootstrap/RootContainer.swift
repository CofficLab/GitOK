import GitOKAppCore
import GitOKCoreKit
import GitOKPluginRegistry
import GitOKUI
import OSLog
import ProjectKit
import SwiftData
import SwiftUI

@MainActor
final class RootContainer: ObservableObject {
    static let shared = RootContainer()

    let repoManager: RepoManager
    let appVM: AppVM
    let pluginService: PluginService
    let themeService: ThemeService
    let gitCoreService: GitCoreService
    let gitOKProjectService: GitOKProjectService
    let navigationService: AppNavigationService
    let pluginDependencies: GitOKPluginDependencies

    let dataVM: DataVM
    let projectVM: ProjectVM
    let themeVM: AppThemeVM

    private init() {
        let container = AppConfig.getContainer()
        self.repoManager = RepoManager(modelContext: ModelContext(container))

        self.pluginDependencies = GitOKPluginDependencies()
        pluginDependencies.register(GitOKAppHostedViewProvider(), for: GitOKAppHostedViewProviding.self)
        self.appVM = AppVM(repoManager: repoManager)
        self.pluginService = PluginService(pluginDependencies: pluginDependencies)
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

        GitOKPluginBootstrap.configureRuntimes(projectService: gitOKProjectService)
    }
}
