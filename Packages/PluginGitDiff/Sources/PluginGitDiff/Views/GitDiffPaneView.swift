import KitGit
import LumiUI
import MagicDiffView
import SwiftUI

/// Git Diff 右侧面板视图。
///
/// 绑定插件自有的 `GitDiffViewModel`：以「当前文件」为唯一驱动（由
/// `GitDiffObserver` 从 `ProjectProviding` 翻译进 ViewModel），commit 只作为
/// 可选上下文决定 diff 来源：
/// - 已选中 commit + 文件：加载该文件在该 commit 中的 diff
///   （`GitDiffLoader.loadDiff`）；
/// - 未选中 commit + 文件（工作区变动）：加载该文件相对工作区的 diff
///   （`GitDiffLoader.loadWorktreeDiff`）。
/// 用旧版同款组件 `MagicDiffView` 渲染（git 原生 unified diff 文本）。
/// 无选中文件时右侧面板整体隐藏（由 `GitDiffPlugin` 通过 observer 监听
/// 当前文件变化控制 `RootTrailingPane.isVisible`，不渲染本视图），
/// 因此本视图内不再需要空占位状态。
///
/// 视图只绑定注入的 ViewModel，不再直接读取 Provider 或注册任何外部监听
/// （commit / 文件 / 仓库数据变化由 `GitDiffObserver` 负责翻译进 ViewModel）。
struct GitDiffPaneView: View {
    @ObservedObject var viewModel: GitDiffViewModel
    @LumiTheme private var theme

    @State private var diffText: String?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var loadedKey: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            AppDivider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(viewModel.$revision) { _ in loadIfNeeded() }
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
            if let hash = viewModel.selectedCommit?.shortHash {
                Text(hash)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var filePath: String? { viewModel.selectedFile }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.selectedFile == nil {
            AppEmptyState(
                icon: "doc.on.doc",
                title: "Select a File",
                description: "Choose a changed file to see its diff."
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

    /// 当「文件（+ 可选 commit 上下文）」组合变化时重新加载 diff。
    private func loadIfNeeded() {
        guard let projectURL = viewModel.selectedProjectURL,
              let path = viewModel.selectedFile else {
            // 无完整上下文：清空并回到占位。
            if loadedKey != nil {
                loadedKey = nil
                diffText = nil
                isLoading = false
                loadError = nil
            }
            return
        }

        let commit = viewModel.selectedCommit
        // 同一文件在「commit 上下文」与「工作区上下文」下的 diff 不同，
        // 用 commit hash（无 commit 时用 "worktree"）区分缓存键。
        let key = "\(commit?.hash ?? "worktree")|\(path)"
        guard loadedKey != key else { return }
        loadedKey = key
        isLoading = true
        diffText = nil
        loadError = nil

        let url = projectURL
        Task.detached(priority: .userInitiated) {
            let result: Result<String, Error>
            if let commit {
                result = Result { try GitDiffLoader.loadDiff(commit: commit.hash, filePath: path, in: url) }
            } else {
                result = Result { try GitDiffLoader.loadWorktreeDiff(filePath: path, in: url) }
            }
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
