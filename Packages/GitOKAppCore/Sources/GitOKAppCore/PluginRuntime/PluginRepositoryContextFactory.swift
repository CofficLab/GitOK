import GitOKCoreKit
import MagicAlert

public struct PluginRepositoryContextHandlers {
    public let canImportRepository: Bool
    public let onProjectExists: GitOKProjectExistenceHandler
    public let onRepositoryImported: GitOKRepositoryImportCompletionHandler
    public let onActivityStatusUpdate: GitOKActivityStatusUpdateHandler
    public let onInfoMessage: GitOKUserMessageHandler
}

public enum PluginRepositoryContextFactory {
    @MainActor
    public static func handlers(data: DataVM, projectVM: ProjectVM) -> PluginRepositoryContextHandlers {
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
}
