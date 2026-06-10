import GitOKAppCore
import Foundation
import GitOKCoreKit
import MagicAlert

@MainActor
final class GitCoreService: GitOKRepositoryServicing, GitOKActivityServicing, GitOKGitCommandServicing {
    let dataVM: DataVM
    let projectVM: ProjectVM

    init(dataVM: DataVM, projectVM: ProjectVM) {
        self.dataVM = dataVM
        self.projectVM = projectVM
    }

    var activityStatus: String? { dataVM.activityStatus }

    func setActivityStatus(_ status: String?) {
        dataVM.activityStatus = status
    }

    func projectExists(at url: URL) -> Bool {
        GitRepositoryBridgeRules.projectExists(
            url: url,
            path: \.path,
            exists: dataVM.repoManager.projectRepo.exists(path:)
        )
    }

    func importRepository(at url: URL) -> Bool {
        GitRepositoryBridgeRules.performRepositoryImportCompletion(
            addProject: { dataVM.addProject(url: url, using: dataVM.repoManager.projectRepo) },
            selectProject: { project, reason in projectVM.setProject(project, reason: reason) }
        )
    }

    func performGitCommand(_ command: GitOKGitCommand) {
        guard let loadedProject = projectVM.project, projectVM.currentProjectIsGitRepository else {
            alert_error("当前没有可操作的 Git 仓库")
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
            return "刷新仓库状态中..."
        case .fetch:
            return "获取远程更新中..."
        case .pull:
            return "拉取中..."
        case .push:
            return "推送中..."
        }
    }
}
