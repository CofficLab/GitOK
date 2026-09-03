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
                "当前工作区没有可提交的改动。"
            case .commitFailed(let message):
                "提交失败：\(message)"
            case .pushFailed(let message):
                "推送失败：\(message)"
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
}
