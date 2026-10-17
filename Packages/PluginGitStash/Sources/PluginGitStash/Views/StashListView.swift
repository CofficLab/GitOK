import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

/// Stash 管理面板：保存新 stash + 列表（apply/pop/drop）
/// （对齐旧版 StashListView 核心能力）。
public struct StashListView: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    let onStashesChanged: () -> Void

    @State private var model: StashListModel

    public init(projects: any ProjectProviding, git: any GitProviding, onStashesChanged: @escaping () -> Void) {
        self.projects = projects
        self.git = git
        self.onStashesChanged = onStashesChanged
        let gitProvider = git
        _model = State(initialValue: StashListModel(
            git: StashGitCapabilityAdapter(git: gitProvider),
            repositoryURL: { [projects] in projects.currentProject?.url },
            onStashesChanged: onStashesChanged
        ))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let message = model.message {
                switch message {
                case .success(let text):
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(theme.success)
                case .failure(let text):
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(theme.warning)
                        .textSelection(.enabled)
                }
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if model.isLoading {
                        StashListSkeletonView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if model.stashes.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 22))
                                .foregroundStyle(theme.textTertiary)
                            Text(GitStashLocalization.string("No stashes yet", bundle: .module))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(model.stashes) { stash in
                            StashRow(
                                stash: stash,
                                isBusy: model.isPerformingAction,
                                onApply: { model.perform(.apply(stash)) },
                                onPop: { model.perform(.pop(stash)) },
                                onDrop: { model.perform(.drop(stash)) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .task { model.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GitStashLocalization.string("Stash", bundle: .module))
                .font(.headline)
            HStack(spacing: 8) {
                AppInputField(
                    LocalizedStringKey(GitStashLocalization.string("Stash message (optional)", bundle: .module)),
                    text: $model.stashMessage
                )
                AppButton(GitStashLocalization.string("Save", bundle: .module), systemImage: "plus", style: .primary, size: .small) {
                    model.save()
                }
                .disabled(model.isPerformingAction)
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}

/// Stash 行：消息 + apply/pop/drop。
public struct StashRow: View {
    let stash: GitStashEntry
    let isBusy: Bool
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    public init(
        stash: GitStashEntry,
        isBusy: Bool,
        onApply: @escaping () -> Void,
        onPop: @escaping () -> Void,
        onDrop: @escaping () -> Void
    ) {
        self.stash = stash
        self.isBusy = isBusy
        self.onApply = onApply
        self.onPop = onPop
        self.onDrop = onDrop
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "archivebox")
                .foregroundStyle(theme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(stash.message.isEmpty ? "stash@{\(stash.index)}" : stash.message)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text("stash@{\(stash.index)}")
                    .font(.appCaption)
                    .foregroundStyle(theme.textTertiary)
            }
            Spacer()
            if !isBusy {
                AppIconButton(systemImage: "arrow.down.to.line", label: GitStashLocalization.string("Apply", bundle: .module), tint: theme.textSecondary) {
                    onApply()
                }
                AppIconButton(systemImage: "arrow.up.to.line", label: GitStashLocalization.string("Pop", bundle: .module), tint: theme.textSecondary) {
                    onPop()
                }
                AppIconButton(systemImage: "trash", label: GitStashLocalization.string("Drop", bundle: .module), tint: theme.warning) {
                    onDrop()
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @LumiTheme private var theme: LumiUITheme
}
