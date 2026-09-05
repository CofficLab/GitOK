import Foundation

/// Cherry-pick 操作的当前状态。
public struct GitCherryPickStatus: Equatable, Sendable {
    public let isCherryPicking: Bool
    public let commitHash: String?

    public init(isCherryPicking: Bool, commitHash: String? = nil) {
        self.isCherryPicking = isCherryPicking
        self.commitHash = commitHash
    }

    public static let inactive = GitCherryPickStatus(isCherryPicking: false)
}

/// Cherry-pick 操作与冲突状态管理。
public enum GitCherryPickOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidCommits
        case notCherryPicking
        case unresolvedConflicts
        case operationFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidCommits:
                LumiPluginLocalization.string("At least one commit is required for cherry-pick.", bundle: .module)
            case .notCherryPicking:
                LumiPluginLocalization.string("No cherry-pick is currently in progress.", bundle: .module)
            case .unresolvedConflicts:
                LumiPluginLocalization.string("Resolve all conflicts before continuing the cherry-pick.", bundle: .module)
            case .operationFailed(let message):
                String(format: LumiPluginLocalization.string("Cherry-pick operation failed: %@", bundle: .module), message)
            }
        }
    }

    /// 读取 `.git/CHERRY_PICK_HEAD`，识别当前是否暂停在 Cherry-pick 流程中。
    public static func status(in repository: URL) -> GitCherryPickStatus {
        guard let headURL = cherryPickHeadURL(in: repository),
              FileManager.default.fileExists(atPath: headURL.path) else {
            return .inactive
        }

        let hash = try? String(contentsOf: headURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return GitCherryPickStatus(isCherryPicking: true, commitHash: hash?.isEmpty == true ? nil : hash)
    }

    /// 按给定顺序 Cherry-pick 一个或多个提交，可选先切换到目标分支。
    @discardableResult
    public static func cherryPick(
        commits: [String],
        onto branch: String? = nil,
        in repository: URL
    ) throws -> String {
        let hashes = commits
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !hashes.isEmpty else { throw Error.invalidCommits }

        if let branch {
            let target = branch.trimmingCharacters(in: .whitespacesAndNewlines)
            if !target.isEmpty {
                _ = try GitProcessRunner.run(["checkout", target], in: repository)
            }
        }

        do {
            return try GitProcessRunner.run(["cherry-pick"] + hashes, in: repository)
        } catch {
            if status(in: repository).isCherryPicking {
                throw GitCherryPickError.conflict(
                    message: message(for: error),
                    files: GitMergeOperation.conflictFiles(in: repository)
                )
            }
            throw Error.operationFailed(message(for: error))
        }
    }

    /// 在所有冲突已解决并暂存后继续 Cherry-pick。
    @discardableResult
    public static func continueCherryPick(in repository: URL) throws -> String {
        guard status(in: repository).isCherryPicking else { throw Error.notCherryPicking }
        guard GitMergeOperation.conflictFiles(in: repository).isEmpty else {
            throw Error.unresolvedConflicts
        }

        do {
            // core.editor=true 避免在后台任务中打开交互式编辑器；多提交序列仍由
            // git cherry-pick --continue 负责推进。
            return try GitProcessRunner.run(
                ["-c", "core.editor=true", "cherry-pick", "--continue"],
                in: repository
            )
        } catch {
            throw Error.operationFailed(message(for: error))
        }
    }

    /// 放弃当前 Cherry-pick，并恢复到开始前的 HEAD 与工作区。
    @discardableResult
    public static func abortCherryPick(in repository: URL) throws -> String {
        guard status(in: repository).isCherryPicking else { throw Error.notCherryPicking }
        do {
            return try GitProcessRunner.run(["cherry-pick", "--abort"], in: repository)
        } catch {
            throw Error.operationFailed(message(for: error))
        }
    }

    private static func cherryPickHeadURL(in repository: URL) -> URL? {
        guard let output = try? GitProcessRunner.run(["rev-parse", "--git-path", "CHERRY_PICK_HEAD"], in: repository) else {
            return nil
        }
        let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return nil }
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        return repository.appendingPathComponent(path)
    }

    private static func message(for error: Swift.Error) -> String {
        (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
    }
}

/// Cherry-pick 因冲突而暂停时保留的错误信息。
public enum GitCherryPickError: Error, LocalizedError, Sendable {
    case conflict(message: String, files: [String])

    public var errorDescription: String? {
        switch self {
        case let .conflict(message, files):
            if files.isEmpty {
                return "Cherry-pick paused with conflicts: \(message)"
            }
            return "Cherry-pick paused with \(files.count) conflict file(s): \(message)"
        }
    }
}
