import Foundation

/// 提交工作流所需的 git 写操作（add / commit / push）。
///
/// 全部通过系统 git CLI 执行（复用 `GitProcessRunner`），与只读加载器保持同一执行通道。
public enum GitCommitOperation {
    public enum Error: Swift.Error, LocalizedError {
        /// 当前工作区没有任何待提交的改动。
        case nothingToCommit
        /// `git commit` 失败（含未配置 user.name/email 等）。
        case commitFailed(String)
        /// `git push` 失败（无 upstream / 网络 / 认证等）。
        case pushFailed(String)

        public var errorDescription: String? {
            switch self {
            case .nothingToCommit:
                LumiPluginLocalization.string("There are no changes to commit in the current workspace.", bundle: .module)
            case .commitFailed(let message):
                String(format: LumiPluginLocalization.string("Commit failed: %@", bundle: .module), message)
            case .pushFailed(let message):
                String(format: LumiPluginLocalization.string("Push failed: %@", bundle: .module), message)
            }
        }
    }

    /// 是否存在已暂存（staged）的改动。
    public static func hasStagedChanges(in repository: URL) throws -> Bool {
        let output = try GitProcessRunner.run(["diff", "--cached", "--name-only"], in: repository)
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 暂存全部改动（`git add -A`）。
    public static func addAll(in repository: URL) throws {
        _ = try GitProcessRunner.run(["add", "-A"], in: repository)
    }

    /// 暂存指定文件（`git add -- <paths>`）。
    ///
    /// 空路径列表按旧版 `GitRepositoryCLI.addFiles(_:)` 的语义视为 no-op。
    /// 路径作为独立进程参数传递，避免文件名中的空格或 `-` 被错误解析。
    public static func stageFiles(_ filePaths: [String], in repository: URL) throws {
        guard !filePaths.isEmpty else { return }
        _ = try GitProcessRunner.run(["add", "--"] + filePaths, in: repository)
    }

    /// 取消暂存指定文件（`git reset -- <paths>`），保留工作区改动。
    ///
    /// 空路径列表按旧版 `GitRepositoryCLI.unstageFiles(_:)` 的语义视为 no-op。
    /// 路径作为独立进程参数传递，避免文件名中的空格或 `-` 被错误解析。
    public static func unstageFiles(_ filePaths: [String], in repository: URL) throws {
        guard !filePaths.isEmpty else { return }
        _ = try GitProcessRunner.run(["reset", "--"] + filePaths, in: repository)
    }

    /// 丢弃指定文件的全部工作区改动（包括暂存内容），不可逆。
    ///
    /// HEAD 中已有的文件恢复到 HEAD；未纳入 HEAD 的文件在取消暂存后从工作区删除。
    public static func discardFileChanges(_ filePath: String, in repository: URL) throws {
        guard !filePath.isEmpty else { return }

        let trackedInHead = try isTrackedInHead(filePath, in: repository)
        try unstageFiles([filePath], in: repository)

        if trackedInHead {
            _ = try GitProcessRunner.run(["restore", "--worktree", "--", filePath], in: repository)
        } else {
            try removeWorkingTreeItem(filePath, in: repository)
        }
    }

    /// 丢弃指定文件的全部工作区改动（包括暂存内容），不可逆。
    ///
    /// 文件按传入顺序逐个处理，空路径列表按 no-op 处理。
    public static func discardFiles(_ filePaths: [String], in repository: URL) throws {
        for filePath in filePaths {
            try discardFileChanges(filePath, in: repository)
        }
    }

    /// 创建提交。
    ///
    /// 消息按空行分段为多个 `-m`（git 会用空行连接各段），支持
    /// 「subject + Co-authored-by」这类多段 message。
    /// 无任何可提交改动时抛 `nothingToCommit`。
    @discardableResult
    public static func commit(message: String, in repository: URL) throws -> String {
        let paragraphs = message
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !paragraphs.isEmpty else {
            throw Error.nothingToCommit
        }

        // 无已暂存改动时直接判定无可提交内容（不依赖 git 错误消息解析）。
        guard try hasStagedChanges(in: repository) else {
            throw Error.nothingToCommit
        }

        var args = ["commit"]
        for paragraph in paragraphs {
            args += ["-m", paragraph]
        }

        do {
            return try GitProcessRunner.run(args, in: repository)
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            if message.localizedCaseInsensitiveContains("nothing to commit")
                || message.localizedCaseInsensitiveContains("no changes added") {
                throw Error.nothingToCommit
            }
            throw Error.commitFailed(message)
        }
    }

    /// 推送到上游分支（`git push`）。
    @discardableResult
    public static func push(in repository: URL) throws -> String {
        do {
            return try GitProcessRunner.run(["push"], in: repository)
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.pushFailed(message)
        }
    }

    private static func isTrackedInHead(_ filePath: String, in repository: URL) throws -> Bool {
        do {
            let output = try GitProcessRunner.run(
                ["ls-tree", "-r", "--name-only", "HEAD", "--", filePath],
                in: repository
            )
            return output.split(separator: "\n").contains { $0 == filePath }
        } catch GitProcessRunner.Error.gitFailed {
            // 没有首个 commit 时 HEAD 不存在，当前路径只能是新增文件。
            return false
        }
    }

    private static func removeWorkingTreeItem(_ filePath: String, in repository: URL) throws {
        let repositoryURL = repository.standardizedFileURL
        let targetURL = URL(fileURLWithPath: filePath, relativeTo: repositoryURL).standardizedFileURL
        let repositoryPath = repositoryURL.path

        guard targetURL.path != repositoryPath,
              targetURL.path.hasPrefix(repositoryPath + "/") else {
            throw NSError(
                domain: "KitGit.GitCommitOperation",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "非法文件路径: \(filePath)"]
            )
        }

        guard FileManager.default.fileExists(atPath: targetURL.path) else { return }
        try FileManager.default.removeItem(at: targetURL)
    }
}
