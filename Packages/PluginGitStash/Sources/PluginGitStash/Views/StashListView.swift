import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// Stash 管理面板：保存新 stash + 列表（apply/pop/drop）
/// （对齐旧版 StashListView 核心能力）。
public struct StashListView: View {
    let projects: any ProjectProviding
    let onStashesChanged: () -> Void

    @State private var stashes: [GitStashEntry] = []
    @State private var isLoading = true
    @State private var stashMessage = ""
    @State private var isPerformingAction = false
    @State private var message: String?
    @State private var errorMessage: String?

    public init(projects: any ProjectProviding, onStashesChanged: @escaping () -> Void) {
        self.projects = projects
        self.onStashesChanged = onStashesChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(theme.success)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(theme.warning)
                    .textSelection(.enabled)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if isLoading {
                        ProgressView("Loading stash list…")
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if stashes.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 22))
                                .foregroundStyle(theme.textTertiary)
                            Text("No stashes yet")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(stashes) { stash in
                            StashRow(
                                stash: stash,
                                isBusy: isPerformingAction,
                                onApply: { perform(.apply(stash)) },
                                onPop: { perform(.pop(stash)) },
                                onDrop: { perform(.drop(stash)) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .onAppear(perform: load)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stash")
                .font(.headline)
            HStack(spacing: 8) {
                AppInputField("Stash message (optional)", text: $stashMessage)
                AppButton("Save", systemImage: "plus", style: .primary, size: .small) {
                    saveStash()
                }
                .disabled(isPerformingAction)
            }
        }
    }

    private var projectURL: URL? {
        projects.currentProject?.url
    }

    private enum StashAction {
        case apply(GitStashEntry)
        case pop(GitStashEntry)
        case drop(GitStashEntry)
    }

    @MainActor
    private func load() {
        guard let url = projectURL else {
            stashes = []
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            let loaded = GitStashOperation.list(in: url)
            await MainActor.run {
                stashes = loaded
                isLoading = false
            }
        }
    }

    @MainActor
    private func saveStash() {
        guard let url = projectURL else { return }
        let text = stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard GitStashOperation.hasChanges(in: url) else {
            errorMessage = "No changes to stash"
            return
        }
        isPerformingAction = true
        errorMessage = nil
        message = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitStashOperation.save(message: text.isEmpty ? nil : text, in: url)
                await MainActor.run {
                    stashMessage = ""
                    isPerformingAction = false
                    message = "Stash saved"
                    onStashesChanged()
                    load()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    @MainActor
    private func perform(_ action: StashAction) {
        guard let url = projectURL else { return }
        isPerformingAction = true
        errorMessage = nil
        message = nil
        Task.detached(priority: .userInitiated) {
            do {
                switch action {
                case .apply(let entry):
                    try GitStashOperation.apply(entry, in: url)
                case .pop(let entry):
                    try GitStashOperation.pop(entry, in: url)
                case .drop(let entry):
                    try GitStashOperation.drop(entry, in: url)
                }
                await MainActor.run {
                    isPerformingAction = false
                    onStashesChanged()
                    load()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    errorMessage = error.localizedDescription
                }
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
                AppIconButton(systemImage: "arrow.down.to.line", label: "Apply", tint: theme.textSecondary) {
                    onApply()
                }
                AppIconButton(systemImage: "arrow.up.to.line", label: "Pop", tint: theme.textSecondary) {
                    onPop()
                }
                AppIconButton(systemImage: "trash", label: "Drop", tint: theme.warning) {
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
