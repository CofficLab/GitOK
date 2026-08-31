import GitOKAppCore
import Foundation
import KitGitOKCore
import MagicAlert

@MainActor
public final class GitCoreService: GitOKRepositoryServicing, GitOKActivityServicing, GitOKGitCommandServicing {
    public let dataVM: DataVM
    public let projectVM: ProjectVM

    public init(dataVM: DataVM, projectVM: ProjectVM) {
        self.dataVM = dataVM
        self.projectVM = projectVM
    }

    public var activityStatus: String? { dataVM.activityStatus }

    public func setActivityStatus(_ status: String?) {
        dataVM.activityStatus = status
    }

    public func projectExists(at url: URL) -> Bool {
        GitRepositoryBridgeRules.projectExists(
            url: url,
            path: \.path,
            exists: dataVM.repoManager.projectRepo.exists(path:)
        )
    }

    public func importRepository(at url: URL) -> Bool {
        GitRepositoryBridgeRules.performRepositoryImportCompletion(
            addProject: { dataVM.addProject(url: url, using: dataVM.repoManager.projectRepo) },
            selectProject: { project, reason in projectVM.setProject(project, reason: reason) }
        )
    }

    public func performGitCommand(_ command: GitOKGitCommand) {
        guard let loadedProject = projectVM.project, projectVM.currentProjectIsGitRepository else {
            alert_error(String(localized: "No Git repository available to operate on"))
            return
        }
        nonisolated(unsafe) let project = loadedProject

        let status = statusText(for: command)

        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                self.dataVM.activityStatus = status
            }

            do {
                switch command {
                case .refresh:
                    await MainActor.run {
                        project.postEvent(
                            name: .projectGitDirectoryDidChange,
                            operation: "menuRefresh"
                        )
                        project.postEvent(
                            name: .projectGitRefsDidChange,
                            operation: "menuRefresh"
                        )
                    }
                case .fetch:
                    try await project.fetchAsync()
                case .pull:
                    try await project.pullAsync()
                case .push:
                    try await project.pushAsync()
                }

                await MainActor.run {
                    self.dataVM.activityStatus = nil
                }
            } catch {
                await MainActor.run {
                    self.dataVM.activityStatus = nil
                    alert_error(error)
                }
            }
        }
    }

    private func statusText(for command: GitOKGitCommand) -> String {
        switch command {
        case .refresh:
            return String(localized: "Refreshing repository status...")
        case .fetch:
            return String(localized: "Fetching remote updates...")
        case .pull:
            return String(localized: "Pulling...")
        case .push:
            return String(localized: "Pushing...")
        }
    }
}
