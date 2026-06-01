import GitOKCoreKit
import MagicAlert

struct GitCloneContextHandlers {
    let canCloneRepository: Bool
    let onProjectExists: GitOKProjectExistenceHandler
    let onCloneRepositoryCompleted: GitOKCloneRepositoryCompletionHandler
    let onActivityStatusUpdate: GitOKActivityStatusUpdateHandler
    let onInfoMessage: GitOKUserMessageHandler
}

enum GitCloneContextFactory {
    @MainActor
    static func handlers(data: DataVM, projectVM: ProjectVM) -> GitCloneContextHandlers {
        GitCloneContextHandlers(
            canCloneRepository: true,
            onProjectExists: { url in
                GitCloneBridgeRules.projectExists(
                    url: url,
                    path: \.path,
                    exists: data.repoManager.projectRepo.exists(path:)
                )
            },
            onCloneRepositoryCompleted: { url in
                GitCloneBridgeRules.performCloneCompletion(
                    addProject: { data.addProject(url: url, using: data.repoManager.projectRepo) },
                    selectProject: projectVM.setProject
                )
            },
            onActivityStatusUpdate: { status in
                data.activityStatus = status
            },
            onInfoMessage: { message in
                GitCloneBridgeRules.performCloneSuccessMessage(message) {
                    alert_info($0)
                }
            }
        )
    }

    @MainActor
    static func make(data: DataVM, projectVM: ProjectVM) -> GitOKPluginContext {
        let handlers = handlers(data: data, projectVM: projectVM)
        return GitOKPluginContext(
            canCloneRepository: handlers.canCloneRepository,
            onProjectExists: handlers.onProjectExists,
            onCloneRepositoryCompleted: handlers.onCloneRepositoryCompleted,
            onActivityStatusUpdate: handlers.onActivityStatusUpdate,
            onInfoMessage: handlers.onInfoMessage
        )
    }
}
