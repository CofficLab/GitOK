import KitGit
import LumiUI
import MagicDiffView
import SwiftUI

/// Git Diff 右侧面板视图。
///
/// 绑定插件自有的 `GitDiffViewModel`：当「当前 commit + 当前文件」变化时
/// （由 `GitDiffObserver` 从 `ProjectProviding` 翻译进 ViewModel），异步加载
/// 该文件的 unified diff（`GitDiffLoader.loadDiff`），用旧版同款组件
/// `MagicDiffView` 渲染。无选中 commit / 文件时显示占位。
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
        .background {
            theme.surface
        }
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
        if viewModel.selectedCommit == nil {
            AppEmptyState(
                icon: "doc.text.magnifyingglass",
                title: "No Commit Selected",
                description: "Select a commit to view its file diffs."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.selectedFile == nil {
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
        guard let commit = viewModel.selectedCommit,
              let projectURL = viewModel.selectedProjectURL,
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
