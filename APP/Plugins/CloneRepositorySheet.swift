import MagicAlert
import PluginGitClone
import SwiftUI

struct CloneRepositorySheet: View {
    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    var body: some View {
        PluginGitClone.CloneRepositorySheet(
            projectExists: { url in
                GitCloneBridgeRules.projectExists(
                    url: url,
                    path: \.path,
                    exists: data.repoManager.projectRepo.exists(path:)
                )
            },
            onCloneCompleted: { url in
                GitCloneBridgeRules.performCloneCompletion(
                    addProject: { data.addProject(url: url, using: data.repoManager.projectRepo) },
                    selectProject: vm.setProject
                )
            },
            setActivityStatus: { status in
                data.activityStatus = status
            },
            onCloneSucceeded: { message in
                GitCloneBridgeRules.performCloneSuccessMessage(message) {
                    alert_info($0)
                }
            }
        )
    }
}
