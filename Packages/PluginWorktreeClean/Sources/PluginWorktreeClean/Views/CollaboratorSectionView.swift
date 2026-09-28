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
            if isApplying && !isCurrent {
                ContentLoadingIndicator(
                    collaboratorLoc("Applying collaborator..."),
                    controlSize: .small
                )
            } else if isLoadingUserConfiguration {
                CollaboratorSkeletonBar()
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

private struct CollaboratorSkeletonBar: View {
    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: 72, height: 12)
            .opacity(
                motionPreference.allowsMotion
                    ? (isBreathing ? 0.58 : 0.86)
                    : 0.72
            )
            .animation(
                motionPreference.allowsMotion
                    ? .easeInOut(duration: 1.15).repeatForever(autoreverses: true)
                    : nil,
                value: isBreathing
            )
            .onAppear {
                isBreathing = motionPreference.allowsMotion
            }
            .onChange(of: motionPreference.allowsMotion) { _, allowsMotion in
                isBreathing = allowsMotion
            }
            .accessibilityHidden(true)
    }
}
