import KitGit
import LumiUI
import MagicDiffView
import ProviderCommit
import SwiftUI

/// Git Diff 右侧面板视图。
///
/// 订阅 `CommitDetailProviding`，当选中 commit + 文件变化时异步加载
/// 该文件的 unified diff（`GitDiffLoader.loadDiff`），用旧版同款组件
/// `MagicDiffView` 渲染。无选中 commit / 文件时显示占位。
struct GitDiffPaneView: View {
    let detail: any CommitDetailProviding
    @LumiTheme private var theme
    @StateObject private var observation: CommitDetailObservationModel

    @State private var diffText: String?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var loadedKey: String?

    init(detail: any CommitDetailProviding) {
        self.detail = detail
        _observation = StateObject(wrappedValue: CommitDetailObservationModel(detail: detail))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            AppDivider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
        .onReceive(observation.$revision) { _ in loadIfNeeded() }
        .onAppear { loadIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.alignleft")
                .font(.appCaptionEmphasized)
            Text(filePath ?? "Diff")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            if let hash = detail.selectedCommit?.shortHash {
                Text(hash)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var filePath: String? { detail.selectedFile }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if detail.selectedCommit == nil {
            AppEmptyState(
                icon: "doc.text.magnifyingglass",
                title: "No Commit Selected",
                description: "Select a commit to view its file diffs."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if detail.selectedFile == nil {
            AppEmptyState(
                icon: "doc.on.doc",
                title: "Select a File",
                description: "Choose a changed file in the commit to see its diff."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isLoading && diffText == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: "Unable to Load Diff",
                description: loadError
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let diffText, !diffText.isEmpty {
            // 与旧版一致：MagicDiffView 直接渲染 git unified diff 文本。
            MagicDiffView(diffOutput: diffText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            AppEmptyState(
                icon: "text.alignleft",
                title: "No Text Diff",
                description: "This file has no parseable text diff."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Loading

    /// 当「commit + 文件」组合变化时重新加载 diff。
    private func loadIfNeeded() {
        guard let commit = detail.selectedCommit,
              let projectURL = detail.selectedProjectURL,
              let path = detail.selectedFile else {
            // 无完整上下文：清空并回到占位。
            if loadedKey != nil {
                loadedKey = nil
                diffText = nil
                isLoading = false
                loadError = nil
            }
            return
        }

        let key = "\(commit.hash)|\(path)"
        guard loadedKey != key else { return }
        loadedKey = key
        isLoading = true
        diffText = nil
        loadError = nil

        let url = projectURL
        let hash = commit.hash
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitDiffLoader.loadDiff(commit: hash, filePath: path, in: url) }
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let text):
                    diffText = text
                case .failure(let error):
                    loadError = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
        }
    }
}

/// 观察模型：订阅 Provider 的观察者事件，转成 @Published revision。
@MainActor
final class CommitDetailObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitDetailObserverHandle)?

    init(detail: any CommitDetailProviding) {
        handle = detail.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
