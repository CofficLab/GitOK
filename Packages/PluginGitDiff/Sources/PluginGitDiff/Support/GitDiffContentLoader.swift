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
            return .text(try loadTextDiff())
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
            return .text(try loadTextDiff())
        }
        return .binary(kind: .binary, data: data)
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
    private func loadBinaryData(
        path: String,
        commit: GitCommit?,
        repository: URL,
        cancellation: GitProcessCancellation?
    ) throws -> Data {
        if let commit {
            return try capability.loadBlobData(
                commit: commit.hash,
                filePath: path,
                in: repository,
                cancellation: cancellation
            )
        }
        return try capability.loadWorktreeFileData(
            filePath: path,
            in: repository,
            cancellation: cancellation
        )
    }
}
