import Foundation

/// Git 提交历史上的写操作。
///
/// 当前先恢复旧版的「Revert This Commit」能力；操作通过系统 git CLI 执行，
/// 让 Git 自己负责工作区脏状态、冲突和 hooks 的校验。
public enum GitHistoryOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidCommit
        case revertFailed(String)
        case undoFailed(String)
        case softResetFailed(String)
        case mixedResetFailed(String)
        case hardResetFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidCommit:
                LumiPluginLocalization.string("A commit is required to revert.", bundle: .module)
            case .revertFailed(let message):
                String(format: LumiPluginLocalization.string("Revert failed: %@", bundle: .module), message)
            case .undoFailed(let message):
                String(format: LumiPluginLocalization.string("Undo failed: %@", bundle: .module), message)
            case .softResetFailed(let message):
                String(format: LumiPluginLocalization.string("Soft reset failed: %@", bundle: .module), message)
            case .mixedResetFailed(let message):
                String(format: LumiPluginLocalization.string("Mixed reset failed: %@", bundle: .module), message)
            case .hardResetFailed(let message):
                String(format: LumiPluginLocalization.string("Hard reset failed: %@", bundle: .module), message)
            }
        }
    }

    /// 回退最新的未推送提交，并用 mixed reset 将该提交的文件改动保留在工作区。
    ///
    /// 只允许在工作区干净且 HEAD 仍是 UI 选中的提交时执行，避免把用户已有的
    /// 未提交改动和并发产生的新提交一起带入不可逆的历史回退。
    @discardableResult
    public static func undoCommit(
        _ commitHash: String,
        parentHash: String,
        in repository: URL
    ) throws -> String {
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedParentHash = parentHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHash.isEmpty, !trimmedParentHash.isEmpty else {
            throw Error.invalidCommit
        }

        do {
            guard try GitStatusLoader.loadStatus(in: repository).isClean else {
                throw Error.undoFailed(
                    LumiPluginLocalization.string("The working tree must be clean before undoing a commit.", bundle: .module)
                )
            }

            let head = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repository)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard head == trimmedHash else {
                throw Error.undoFailed(
                    LumiPluginLocalization.string("The selected commit is no longer the current HEAD.", bundle: .module)
                )
            }

            return try GitProcessRunner.run(
                ["reset", "--mixed", trimmedParentHash],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.undoFailed(message)
        }
    }

    /// 将 HEAD 软重置到指定提交，并把后续提交的文件改动保留在暂存区。
    ///
    /// 只允许在工作区干净且 HEAD 仍匹配调用方加载到的值时执行，防止旧列表中的
    /// 提交在用户或其他工具已经改变仓库后被误操作。
    @discardableResult
    public static func softReset(
        to targetHash: String,
        expectedHead: String,
        in repository: URL
    ) throws -> String {
        let trimmedTargetHash = targetHash.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExpectedHead = expectedHead.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTargetHash.isEmpty, !trimmedExpectedHead.isEmpty else {
            throw Error.invalidCommit
        }

        do {
            guard try GitStatusLoader.loadStatus(in: repository).isClean else {
                throw Error.softResetFailed(
                    LumiPluginLocalization.string("The working tree must be clean before resetting history.", bundle: .module)
                )
            }

            let head = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repository)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard head == trimmedExpectedHead else {
                throw Error.softResetFailed(
                    LumiPluginLocalization.string("The current HEAD changed before the reset could start.", bundle: .module)
                )
            }

            return try GitProcessRunner.run(
                ["reset", "--soft", trimmedTargetHash],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.softResetFailed(message)
        }
    }

    /// 将 HEAD 混合重置到指定提交，并把后续提交的文件改动保留在工作区但取消暂存。
    @discardableResult
    public static func mixedReset(
        to targetHash: String,
        expectedHead: String,
        in repository: URL
    ) throws -> String {
        let trimmedTargetHash = targetHash.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExpectedHead = expectedHead.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTargetHash.isEmpty, !trimmedExpectedHead.isEmpty else {
            throw Error.invalidCommit
        }

        do {
            guard try GitStatusLoader.loadStatus(in: repository).isClean else {
                throw Error.mixedResetFailed(
                    LumiPluginLocalization.string("The working tree must be clean before resetting history.", bundle: .module)
                )
            }

            let head = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repository)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard head == trimmedExpectedHead else {
                throw Error.mixedResetFailed(
                    LumiPluginLocalization.string("The current HEAD changed before the reset could start.", bundle: .module)
                )
            }

            return try GitProcessRunner.run(
                ["reset", "--mixed", trimmedTargetHash],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.mixedResetFailed(message)
        }
    }

    /// 将 HEAD、暂存区和已跟踪工作区文件硬重置到指定提交。
    ///
    /// 这是破坏性操作：目标提交之后的本地提交和已跟踪未提交改动都会被 Git
    /// 丢弃。调用方必须先展示明确的确认弹窗；这里仍校验 HEAD，避免旧列表误操作。
    @discardableResult
    public static func hardReset(
        to targetHash: String,
        expectedHead: String,
        in repository: URL
    ) throws -> String {
        let trimmedTargetHash = targetHash.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExpectedHead = expectedHead.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTargetHash.isEmpty, !trimmedExpectedHead.isEmpty else {
            throw Error.invalidCommit
        }

        do {
            let head = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repository)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard head == trimmedExpectedHead else {
                throw Error.hardResetFailed(
                    LumiPluginLocalization.string("The current HEAD changed before the reset could start.", bundle: .module)
                )
            }

            return try GitProcessRunner.run(
                ["reset", "--hard", trimmedTargetHash],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            let message = (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
            throw Error.hardResetFailed(message)
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
