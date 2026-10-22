import Foundation
import KitGit

/// diff 面板加载到的内容。
enum GitDiffLoadedContent: Equatable {
    /// 可渲染的文本补丁（git 原生 unified diff）。
    case text(String)
    /// 二进制内容（图片 / 音视频 / office / 未知二进制）。
    case binary(kind: GitDiffContentKind, data: Data)
    /// PDF 对比预览：当前版本与父提交版本。
    case pdfComparison(current: Data?, previous: Data?)
    /// 文件没有可渲染的文本差异（如空文件被删除）。
    case noTextDiff
}

/// diff 内容加载器。
///
/// 从视图中抽出，使「选文件 → 决定加载什么 → 得到什么内容」这条链路可以
/// 被单元测试直接覆盖，而不必渲染 SwiftUI 视图。
///
/// 加载策略（与 `GitDiffContentDetector` 配合）：
/// - 文本文件：读 unified diff 文本；
/// - PDF：读当前 commit 与父 commit 的两份 blob 做对比；
/// - 其它二进制（图片 / 音视频 / office）：读原始字节做内联预览。
struct GitDiffContentLoader: Sendable {
    /// 内联预览的字节上限，超出则提示用系统默认应用打开。
    static let maxInlinePreviewBytes = 50 * 1024 * 1024

    private let capability: any GitDiffContentCapability

    init(capability: any GitDiffContentCapability) {
        self.capability = capability
    }

    /// 加载指定文件在指定上下文中的 diff 内容。
    ///
    /// - Parameters:
    ///   - path: 仓库内相对路径。
    ///   - commit: 选中的 commit；为 nil 时表示工作区（未提交）上下文。
    ///   - repository: 仓库根目录。
    ///   - cancellation: 取消令牌。
    func load(
        path: String,
        commit: GitCommit?,
        repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> GitDiffLoadedContent {
        let previewKind = GitDiffContentDetector.kind(forPath: path)
        let needsContentInspection = GitDiffContentDetector.needsContentInspection(forPath: path)

        func loadTextDiff() throws -> String {
            if let commit {
                return try capability.loadDiff(
                    commit: commit.hash,
                    filePath: path,
                    in: repository,
                    cancellation: cancellation
                )
            }
            return try capability.loadWorktreeDiff(
                filePath: path,
                in: repository,
                cancellation: cancellation
            )
        }

        guard previewKind != nil || needsContentInspection else {
            return textDiffContent(try loadTextDiff())
        }

        if previewKind == .pdf, let commit {
            return try loadPDFComparison(
                path: path,
                commit: commit,
                repository: repository,
                cancellation: cancellation
            )
        }

        let data = try loadBinaryData(
            path: path,
            commit: commit,
            repository: repository,
            cancellation: cancellation
        )
        guard data.count <= Self.maxInlinePreviewBytes else {
            throw GitDiffPreviewError.fileTooLarge(data.count)
        }

        if let detectedKind = GitDiffContentDetector.kind(forPath: path, data: data) {
            return .binary(kind: detectedKind, data: data)
        }
        if needsContentInspection && GitDiffContentDetector.isLikelyText(data) {
            return textDiffContent(try loadTextDiff())
        }
        return .binary(kind: .binary, data: data)
    }

    /// 把 unified diff 文本包装成加载结果。
    ///
    /// git 对「文件被删除且原文件为空」只输出 `deleted file mode` 而没有 `@@`
    /// hunk。`MagicDiffView` 的解析器要求 hunk 存在，否则产出空的 diffItems，
    /// 面板会渲染成一块什么都没有的空白区域。此时应返回 `noTextDiff`，
    /// 让视图显示明确的空状态，而不是一个看起来像加载失败的面板。
    private func textDiffContent(_ diffText: String) -> GitDiffLoadedContent {
        guard Self.containsHunkHeader(diffText) else {
            return .noTextDiff
        }
        return .text(diffText)
    }

    /// 补丁里是否存在 hunk 头。
    ///
    /// 不能只用 `contains("@@")`：diff 文本会带上文件路径，路径本身含 `@@`
    /// 时（如 `notes@@draft.md`）会被误判成 hunk，导致本该显示空状态的
    /// 场景重新变成空白面板。hunk 头必须形如 `@@ -1,3 +1,4 @@`，
    /// 即以 `@@ ` 开头并带行号区间。
    private static func containsHunkHeader(_ diffText: String) -> Bool {
        diffText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .contains { line in
                guard line.hasPrefix("@@ ") else { return false }
                // 形如 "@@ -oldStart,oldCount +newStart,newCount @@"
                let ranges = line.dropFirst(3).split(separator: "@@", maxSplits: 1, omittingEmptySubsequences: false)
                guard let spec = ranges.first else { return false }
                let parts = spec.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count == 2 else { return false }
                return parts.allSatisfy { part in
                    part.hasPrefix("-") || part.hasPrefix("+")
                }
            }
    }

    /// 加载 PDF 的「当前版本 vs 父提交版本」两份数据。
    private func loadPDFComparison(
        path: String,
        commit: GitCommit,
        repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> GitDiffLoadedContent {
        func loadOptionalBlob(_ hash: String) throws -> Data? {
            do {
                return try capability.loadBlobData(
                    commit: hash,
                    filePath: path,
                    in: repository,
                    cancellation: cancellation
                )
            } catch {
                if cancellation?.isCancelled == true { throw error }
                return nil
            }
        }

        let currentData = try loadOptionalBlob(commit.hash)
        let previousData: Data?
        if let parentHash = commit.parentHashes.first {
            previousData = try loadOptionalBlob(parentHash)
        } else {
            previousData = nil
        }
        if let currentData, currentData.count > Self.maxInlinePreviewBytes {
            throw GitDiffPreviewError.fileTooLarge(currentData.count)
        }
        if let previousData, previousData.count > Self.maxInlinePreviewBytes {
            throw GitDiffPreviewError.fileTooLarge(previousData.count)
        }
        guard currentData != nil || previousData != nil else {
            throw GitDiffLoaderError.invalidFilePath(path)
        }
        return .pdfComparison(current: currentData, previous: previousData)
    }

    /// 加载二进制内容。
    ///
    /// 文件被删除时当前 commit 没有该 blob，`git cat-file` 会以退出码 128
    /// 失败。此时应回退到父提交读取，展示被删掉的内容，而不是把 git 的
    /// 错误冒泡成「Unable to Load Diff」。
    private func loadBinaryData(
        path: String,
        commit: GitCommit?,
        repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        if let commit {
            do {
                return try capability.loadBlobData(
                    commit: commit.hash,
                    filePath: path,
                    in: repository,
                    cancellation: cancellation
                )
            } catch {
                if cancellation?.isCancelled == true { throw error }
                guard
                    let parentHash = commit.parentHashes.first,
                    let fallbackData = try? capability.loadBlobData(
                        commit: parentHash,
                        filePath: path,
                        in: repository,
                        cancellation: cancellation
                    )
                else {
                    throw error
                }
                return fallbackData
            }
        }
        return try capability.loadWorktreeFileData(
            filePath: path,
            in: repository,
            cancellation: cancellation
        )
    }
}
