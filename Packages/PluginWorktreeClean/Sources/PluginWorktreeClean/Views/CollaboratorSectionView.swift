import LumiUI
import ProviderContentView
import ProviderGitUser
import SwiftUI

private func collaboratorLoc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// 工作区干净视图底部的协作者区块。
///
/// 协作者数据来自 WorktreeCleanViewModel；视图只负责渲染和发送应用意图，
/// 不直接读取 Provider 或仓库配置。
struct CollaboratorSectionView: View {
    let collaborators: [Collaborator]
    let currentUserName: String
    let currentUserEmail: String
    let isLoadingUserConfiguration: Bool
    let isApplying: Bool
    let onApply: (Collaborator) -> Void

    var body: some View {
        AppSettingSection(title: collaboratorLoc("Collaborators"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                if collaborators.isEmpty {
                    AppSettingRow(
                        title: collaboratorLoc("No Collaborators"),
                        description: collaboratorLoc("Add collaborators in User Info settings."),
                        icon: "person.2"
                    ) {
                        EmptyView()
                    }
                } else {
                    ForEach(collaborators) { collaborator in
                        collaboratorRow(collaborator)
                        if collaborator.id != collaborators.last?.id {
                            Divider().padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private func collaboratorRow(_ collaborator: Collaborator) -> some View {
        let isCurrent = currentUserName == collaborator.name && currentUserEmail == collaborator.email

        return AppSettingRow(
            title: collaborator.title,
            description: collaborator.email,
            icon: "person.2"
        ) {
            if isLoadingUserConfiguration || (isApplying && !isCurrent) {
                ContentLoadingIndicator(
                    isApplying ? collaboratorLoc("Applying collaborator...") : collaboratorLoc("Loading Git user..."),
                    controlSize: .small
                )
            } else if isCurrent {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            } else {
                AppButton(
                    collaboratorLoc("Apply"),
                    systemImage: "checkmark.circle",
                    style: .secondary,
                    size: .small
                ) {
                    onApply(collaborator)
                }
            }
        }
    }
}
