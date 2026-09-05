import Foundation

/// Git 提交历史上的写操作。
///
/// 当前先恢复旧版的「Revert This Commit」能力；操作通过系统 git CLI 执行，
/// 让 Git 自己负责工作区脏状态、冲突和 hooks 的校验。
public enum GitHistoryOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidCommit
        case revertFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidCommit:
                LumiPluginLocalization.string("A commit is required to revert.", bundle: .module)
            case .revertFailed(let message):
                String(format: LumiPluginLocalization.string("Revert failed: %@", bundle: .module), message)
            }
        }
    }

    /// 反转指定提交并创建一个新的 revert 提交。
    ///
    /// 使用 `--no-edit` 避免在 UI 操作中打开终端编辑器；如果工作区有冲突、
    /// 提交是无法直接反转的 merge commit，或 hooks 拒绝提交，原始 git 错误会被
    /// 保留并交给上层展示。
    @discardableResult
    public static func revertCommit(_ commitHash: String, in repository: URL) throws -> String {
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHash.isEmpty else {
            throw Error.invalidCommit
        }

        do {
            return try GitProcessRunner.run(
                ["revert", "--no-edit", trimmedHash],
                in: repository
            )
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.revertFailed(message)
        }
    }
}
