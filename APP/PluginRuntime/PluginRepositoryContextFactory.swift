import GitOKCoreKit
import MagicAlert

struct PluginRepositoryContextHandlers {
    let canImportRepository: Bool
    let onProjectExists: GitOKProjectExistenceHandler
    let onRepositoryImported: GitOKRepositoryImportCompletionHandler
    let onActivityStatusUpdate: GitOKActivityStatusUpdateHandler
    let onInfoMessage: GitOKUserMessageHandler
}

enum PluginRepositoryContextFactory {
    @MainActor
    static func handlers(data: DataVM, projectVM: ProjectVM) -> PluginRepositoryContextHandlers {
        PluginRepositoryContextHandlers(
            canImportRepository: true,
            onProjectExists: { url in
                GitRepositoryBridgeRules.projectExists(
                    url: url,
                    path: \.path,
                    exists: data.repoManager.projectRepo.exists(path:)
                )
            },
            onRepositoryImported: { url in
                GitRepositoryBridgeRules.performRepositoryImportCompletion(
                    addProject: { data.addProject(url: url, using: data.repoManager.projectRepo) },
                    selectProject: projectVM.setProject
                )
            },
            onActivityStatusUpdate: { status in
                data.activityStatus = status
            },
            onInfoMessage: { message in
                GitRepositoryBridgeRules.performRepositoryImportSuccessMessage(message) {
                    alert_info($0)
                }
            }
        )
    }

    @MainActor
    static func make(data: DataVM, projectVM: ProjectVM) -> GitOKPluginContext {
        let handlers = handlers(data: data, projectVM: projectVM)
        return GitOKPluginContext(
            canImportRepository: handlers.canImportRepository,
            onProjectExists: handlers.onProjectExists,
            onRepositoryImported: handlers.onRepositoryImported,
            onActivityStatusUpdate: handlers.onActivityStatusUpdate,
            onInfoMessage: handlers.onInfoMessage
        )
    }
}
