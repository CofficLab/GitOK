import KitGit
import LumiUI
import MagicDiffView
import SwiftUI

/// Git Diff 右侧面板视图。
///
/// 绑定插件自有的 `GitDiffViewModel`：以「当前文件」为唯一驱动（由
/// `GitDiffObserver` 从 `ProjectProviding` 翻译进 ViewModel），commit 只作为
/// 可选上下文决定 diff 来源：
/// - 已选中 commit + 文件：加载该文件在该 commit 中的 diff；
/// - 未选中 commit + 文件（工作区变动）：加载该文件相对工作区的 diff。
/// 加载逻辑由 `GitDiffContentLoader` 承担（只依赖 `GitDiffContentCapability`
/// 窄能力），本视图只负责把加载结果映射成 UI 状态。
/// 用旧版同款组件 `MagicDiffView` 渲染（git 原生 diff 文本）。
/// 无选中文件时右侧面板整体隐藏（由 `GitDiffPlugin` 通过 observer 监听
/// 当前文件变化控制 `RootTrailingPane.isVisible`，不渲染本视图），
/// 因此本视图内不再需要空占位状态。
///
/// 视图只绑定注入的 ViewModel，不再直接读取 Provider 或注册任何外部监听
/// （commit / 文件 / 仓库数据变化由 `GitDiffObserver` 负责翻译进 ViewModel）。
struct GitDiffPaneView: View {
    @ObservedObject var viewModel: GitDiffViewModel
    let contentLoader: GitDiffContentLoader
    @LumiTheme private var theme

    @State private var loadedContent: GitDiffLoadedContent?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var loadedKey: String?
    @State private var loadToken = 0
    @State private var activeReadCancellation: GitProcessCancellation?

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
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel("Git diff panel")
                .accessibilityIdentifier("gitok.git.diff.panel")
        }
        .onReceive(viewModel.$revision) { _ in loadIfNeeded() }
        .onAppear { loadIfNeeded() }
        .onDisappear { invalidateLoad() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: GitDiffContentDetector.kind(forPath: filePath ?? "")?.systemImage ?? "text.alignleft")
                .font(.appCaptionEmphasized)
            Text(filePath ?? GitDiffLocalization.string("Diff", bundle: .module))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityIdentifier("gitok.git.diff.file")
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
                title: GitDiffLocalization.string("Select a File", bundle: .module),
                description: GitDiffLocalization.string("Choose a changed file to see its diff.", bundle: .module)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isLoading && loadedContent == nil {
            GitDiffSkeletonView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: GitDiffLocalization.string("Unable to Load Diff", bundle: .module),
                description: loadError
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch loadedContent {
            case let .text(diffText)?:
                MagicDiffView(diffOutput: diffText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .binary(kind, data)?:
                GitBinaryPreviewView(kind: kind, data: data, path: filePath ?? "")
            case let .pdfComparison(current, previous)?:
                GitPDFComparisonPreview(
                    currentData: current,
                    previousData: previous,
                    path: filePath ?? ""
                )
                // identity 绑定到「文件 + 两个版本是否存在」：切换文件时
                // 视图被重建，`showingPrevious` 才会按新内容重新取默认值。
                // 否则先看「被删除的 PDF」再切到「修改过的 PDF」时，
                // 新文件会沿用旧文件的 `showingPrevious = true`。
                .id(PDFPreviewIdentity(path: filePath ?? "", hasCurrent: current != nil, hasPrevious: previous != nil))
            case .noTextDiff?, nil:
                AppEmptyState(
                    icon: "text.alignleft",
                    title: GitDiffLocalization.string("No Text Diff", bundle: .module),
                    description: GitDiffLocalization.string("This file has no parseable text diff.", bundle: .module)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Loading

    /// 当「文件（+ 可选 commit 上下文）」组合变化时重新加载 diff。
    private func loadIfNeeded() {
        guard let projectURL = viewModel.selectedProjectURL,
              let path = viewModel.selectedFile else {
            // 无完整上下文：清空并回到占位。
            invalidateLoad()
            return
        }

        let commit = viewModel.selectedCommit
        // 同一文件在「commit 上下文」与「工作区上下文」下的 diff 不同，
        // 用 commit hash（无 commit 时用 "worktree"）区分缓存键。
        let key = "\(projectURL.standardizedFileURL.path)|\(commit?.hash ?? "worktree")|\(path)"
        guard loadedKey != key else { return }
        activeReadCancellation?.cancel()
        let cancellation = GitProcessCancellation(forceKillAfter: 1)
        activeReadCancellation = cancellation
        loadToken &+= 1
        let token = loadToken
        loadedKey = key
        isLoading = true
        loadedContent = nil
        loadError = nil

        let url = projectURL
        let loader = contentLoader
        Task.detached(priority: .userInitiated) {
            let result: Result<GitDiffLoadedContent, Error> = Result {
                try loader.load(
                    path: path,
                    commit: commit,
                    repository: url,
                    cancellation: cancellation
                )
            }
            await MainActor.run {
                guard token == loadToken, loadedKey == key else { return }
                activeReadCancellation = nil
                isLoading = false
                switch result {
                case .success(let content):
                    loadedContent = content
                case .failure(let error):
                    loadError = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
        }
    }

    private func invalidateLoad() {
        activeReadCancellation?.cancel()
        activeReadCancellation = nil
        loadToken &+= 1
        loadedKey = nil
        loadedContent = nil
        isLoading = false
        loadError = nil
    }
}
