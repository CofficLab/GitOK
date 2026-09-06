import LumiUI
import ProviderGitUser
import SwiftUI

private func presetLoc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// 工作区干净视图底部的 Git 用户预设区块。
///
/// 预设数据来自 WorktreeCleanViewModel；视图只负责渲染和发送应用 / 管理意图，
/// 不直接读取 Provider 或仓库配置。
struct GitUserPresetSectionView: View {
    let presets: [GitUserPreset]
    let currentUserName: String
    let currentUserEmail: String
    let isLoadingUserConfiguration: Bool
    let isApplying: Bool
    let onApply: (GitUserPreset) -> Void
    let onManage: (() -> Void)?

    var body: some View {
        AppSettingSection(title: presetLoc("Git User Presets"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                if presets.isEmpty {
                    AppSettingRow(
                        title: presetLoc("No Presets"),
                        description: presetLoc("Add a user preset in User Info settings."),
                        icon: "person.crop.circle"
                    ) {
                        EmptyView()
                    }
                } else {
                    ForEach(presets) { preset in
                        presetRow(preset)
                        if preset.id != presets.last?.id {
                            Divider().padding(.vertical, 8)
                        }
                    }
                }

                if onManage != nil {
                    Divider().padding(.vertical, 8)
                    AppSettingRow(
                        title: presetLoc("Manage Presets"),
                        description: presetLoc("Add, edit, or delete user presets."),
                        icon: "gearshape"
                    ) {
                        AppIconButton(systemImage: "gearshape", size: .regular) {
                            onManage?()
                        }
                    }
                }
            }
        }
    }

    private func presetRow(_ preset: GitUserPreset) -> some View {
        let isCurrent = currentUserName == preset.name && currentUserEmail == preset.email

        return AppSettingRow(
            title: preset.title,
            description: preset.email,
            icon: "person.crop.circle"
        ) {
            if isLoadingUserConfiguration || (isApplying && !isCurrent) {
                ProgressView().controlSize(.small)
            } else if isCurrent {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            } else {
                AppButton(
                    presetLoc("Apply"),
                    systemImage: "checkmark.circle",
                    style: .secondary,
                    size: .small
                ) {
                    onApply(preset)
                }
            }
        }
    }
}
