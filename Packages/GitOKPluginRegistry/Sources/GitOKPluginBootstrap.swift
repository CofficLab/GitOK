import GitAutoPushPlugin
import GitOKCoreKit
import ProjectKit

@MainActor
public enum GitOKPluginBootstrap {
    public static func configureRuntimes(projectService: GitOKProjectServicing) {
        AutoPushService.shared.register(currentProjectProvider: {
            guard let projectPath = projectService.projectPath,
                  let projectTitle = projectService.projectTitle else {
                return nil
            }
            return AutoPushProjectSnapshot(
                projectPath: projectPath,
                projectTitle: projectTitle,
                branchName: projectService.branchName,
                isGitRepository: projectService.isGitRepository
            )
        })
    }
}
