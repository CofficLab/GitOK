import GitOKCoreKit
import MagicAlert
import PluginGitClone

enum GitClonePluginContextFactory {
    @MainActor
    static func make(data: DataVM, projectVM: ProjectVM) -> GitOKPluginContext {
        GitOKPluginContext(
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
}
