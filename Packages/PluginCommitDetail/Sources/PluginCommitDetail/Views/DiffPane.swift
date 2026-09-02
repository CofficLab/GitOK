import KitGit
import LumiUI
import SwiftUI

/// diff 详情面板：异步加载指定文件在该 commit 中的 unified diff 并着色渲染。
struct DiffPane: View {
    let commit: GitCommit
    let projectURL: URL
    let filePath: String

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
        .onAppear { loadIfNeeded() }
        .onChange(of: filePath) { _, _ in loadIfNeeded() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.alignleft")
                .font(.appCaptionEmphasized)
            Text(filePath)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if let diffText {
                Text("\(diffText.count)")
                    .font(.appMicro)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && diffText == nil {
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
            DiffTextView(diffText: diffText)
        } else {
            AppEmptyState(
                icon: "text.alignleft",
                title: "No Text Diff",
                description: "This file has no parseable text diff."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadIfNeeded() {
        let key = "\(commit.hash)|\(filePath)"
        guard loadedKey != key else { return }
        loadedKey = key
        isLoading = true
        diffText = nil
        loadError = nil

        let url = projectURL
        let hash = commit.hash
        let path = filePath
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

// MARK: - Unified Diff Text View

/// 将 unified diff 文本渲染为按行着色的可滚动视图。
///
/// - `+` 行：绿色背景；
/// - `-` 行：红色背景；
/// - `@@ hunk` 头：蓝色；
/// - `diff --git` / 文件头：次级色；
/// - 其它（上下文 / 空行）：默认前景色。
struct DiffTextView: View {
    @LumiTheme private var theme
    let diffText: String

    private var lines: [(text: String, kind: LineKind)] {
        diffText.components(separatedBy: "\n").map { line in
            if line.hasPrefix("+++") || line.hasPrefix("---") || line.hasPrefix("diff --git")
                || line.hasPrefix("new file") || line.hasPrefix("deleted file")
                || line.hasPrefix("index ") || line.hasPrefix("similarity ") || line.hasPrefix("rename ") {
                return (line, .meta)
            } else if line.hasPrefix("@@") {
                return (line, .hunk)
            } else if line.hasPrefix("+") {
                return (line, .added)
            } else if line.hasPrefix("-") {
                return (line, .removed)
            } else {
                return (line, .context)
            }
        }
    }

    var body: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, entry in
                    Text(entry.text.isEmpty ? " " : entry.text)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(foreground(entry.kind))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(background(entry.kind))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 0.5)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private enum LineKind {
        case added, removed, hunk, meta, context
    }

    private func foreground(_ kind: LineKind) -> Color {
        switch kind {
        case .added: theme.success
        case .removed: theme.error
        case .hunk: theme.info
        case .meta: theme.textSecondary
        case .context: theme.textPrimary
        }
    }

    private func background(_ kind: LineKind) -> Color {
        switch kind {
        case .added: theme.success.opacity(0.12)
        case .removed: theme.error.opacity(0.12)
        case .hunk: theme.info.opacity(0.08)
        case .meta, .context: .clear
        }
    }
}
