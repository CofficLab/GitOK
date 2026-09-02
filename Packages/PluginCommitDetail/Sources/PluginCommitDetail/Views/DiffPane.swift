import KitGit
import LumiUI
import SwiftUI

/// diff 详情面板：异步加载指定文件在该 commit 中的 unified diff 并着色渲染。
struct DiffPane: View {
    let commit: GitCommit
    let projectURL: URL
    let filePath: String
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
                    .foregroundStyle(theme.textTertiary)
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
/// 增强版 diff 行视图：解析 unified diff，渲染新旧行号列 + 分层着色。
///
/// - 行号列：左侧旧行号、右侧新行号（右对齐、等宽、次级色）；
/// - `+` 行：绿色背景；`-` 行：红色背景；
/// - `@@ hunk` 头：加粗 + 淡蓝背景；
/// - `diff --git` 等文件头：次级色；
/// - 上下文行：默认前景色。
struct DiffTextView: View {
    @LumiTheme private var theme
    let diffText: String

    private var parsed: [DiffLine] {
        Self.parse(diffText)
    }

    var body: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(parsed) { line in
                    diffRow(line)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: - Row

    private func diffRow(_ line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // 行号列
            HStack(spacing: 0) {
                lineNumber(line.oldLine)
                lineNumber(line.newLine)
            }
            .padding(.vertical, 1)
            .background(numberBackground(line.kind))

            // 内容列
            Text(line.text.isEmpty ? " " : line.text)
                .font(line.kind == .hunk
                    ? .system(size: 11.5, weight: .semibold, design: .monospaced)
                    : .system(size: 11.5, design: .monospaced))
                .foregroundStyle(foreground(line.kind))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 1)
                .background(background(line.kind))
        }
    }

    @ViewBuilder
    private func lineNumber(_ n: Int?) -> some View {
        if let n {
            Text("\(n)")
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 32, alignment: .trailing)
                .padding(.trailing, 6)
        } else {
            Text("")
                .frame(width: 38)
        }
    }

    // MARK: - Parsing

    /// 解析 unified diff：跟踪 hunk 内的新旧行号。
    private static func parse(_ diffText: String) -> [DiffLine] {
        var result: [DiffLine] = []
        var oldLine = 0
        var newLine = 0

        for raw in diffText.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.hasPrefix("@@") {
                if let (oldStart, newStart) = parseHunk(line) {
                    oldLine = oldStart
                    newLine = newStart
                }
                result.append(DiffLine(text: line, kind: .hunk, oldLine: nil, newLine: nil))
            } else if line.hasPrefix("+") && !line.hasPrefix("+++") {
                newLine += 1
                result.append(DiffLine(text: line, kind: .added, oldLine: nil, newLine: newLine))
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                oldLine += 1
                result.append(DiffLine(text: line, kind: .removed, oldLine: oldLine, newLine: nil))
            } else if isMeta(line) {
                result.append(DiffLine(text: line, kind: .meta, oldLine: nil, newLine: nil))
            } else {
                // 上下文（含 hunk 内的空行）推进行号。
                if oldLine > 0 { oldLine += 1 }
                if newLine > 0 { newLine += 1 }
                result.append(DiffLine(text: line, kind: .context, oldLine: oldLine, newLine: newLine))
            }
        }
        return result
    }

    private static func isMeta(_ line: String) -> Bool {
        line.hasPrefix("diff --git") || line.hasPrefix("index ")
            || line.hasPrefix("new file") || line.hasPrefix("deleted file")
            || line.hasPrefix("similarity ") || line.hasPrefix("rename ")
            || line.hasPrefix("+++") || line.hasPrefix("---")
            || line.hasPrefix("Binary files")
    }

    /// 解析 `@@ -oldStart[,oldCount] +newStart[,newCount] @@`。
    private static func parseHunk(_ line: String) -> (Int, Int)? {
        let pattern = #"^@@\s+-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s+@@"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length))
        else { return nil }
        guard let oldRange = Range(match.range(at: 1), in: line),
              let newRange = Range(match.range(at: 2), in: line),
              let old = Int(line[oldRange]),
              let new = Int(line[newRange])
        else { return nil }
        return (old, new)
    }

    // MARK: - Styling

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
        case .added: theme.success.opacity(0.13)
        case .removed: theme.error.opacity(0.11)
        case .hunk: theme.info.opacity(0.10)
        case .meta, .context: .clear
        }
    }

    private func numberBackground(_ kind: LineKind) -> Color {
        switch kind {
        case .added: theme.success.opacity(0.08)
        case .removed: theme.error.opacity(0.08)
        case .hunk: theme.info.opacity(0.06)
        case .meta, .context: .clear
        }
    }
}

/// diff 行：文本 + 类型 + 新旧行号。
struct DiffLine: Identifiable {
    let id = UUID()
    let text: String
    let kind: LineKind
    let oldLine: Int?
    let newLine: Int?
}

/// diff 行类型。
enum LineKind {
    case added, removed, hunk, meta, context
}
