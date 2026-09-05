import Foundation

/// 分支摘要（对齐旧版 KitGitCore.GitBranchSummary）。
public struct GitBranchSummary: Identifiable, Equatable, Hashable, Sendable {
    public let name: String
    public let isRemote: Bool
    public let isCurrent: Bool

    public init(name: String, isRemote: Bool, isCurrent: Bool) {
        self.name = name
        self.isRemote = isRemote
        self.isCurrent = isCurrent
    }

    public var id: String { name }
}

/// 分支操作：列表、新建、切换、删除（对齐旧版 GitRepositoryCLI 分支能力）。
public enum GitBranchOperation {
    public enum Error: Swift.Error, LocalizedError {
        case invalidBranchName
        case invalidRemoteName
        case cannotDeleteRemoteHead
        case renameFailed(String)
        case upstreamFailed(String)
        case publishFailed(String)
        case deleteRemoteFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidBranchName:
                LumiPluginLocalization.string("A valid branch name is required.", bundle: .module)
            case .invalidRemoteName:
                LumiPluginLocalization.string("A remote name is required.", bundle: .module)
            case .cannotDeleteRemoteHead:
                LumiPluginLocalization.string("The remote HEAD branch cannot be deleted.", bundle: .module)
            case .renameFailed(let message):
                String(format: LumiPluginLocalization.string("Branch rename failed: %@", bundle: .module), message)
            case .upstreamFailed(let message):
                String(format: LumiPluginLocalization.string("Upstream update failed: %@", bundle: .module), message)
            case .publishFailed(let message):
                String(format: LumiPluginLocalization.string("Branch publish failed: %@", bundle: .module), message)
            case .deleteRemoteFailed(let message):
                String(format: LumiPluginLocalization.string("Remote branch deletion failed: %@", bundle: .module), message)
            }
        }
    }

    /// 列出本地与远程分支。
    public static func listBranches(in repository: URL) throws -> [GitBranchSummary] {
        // 本地分支：`git for-each-ref refs/heads --format=%(refname:short)`，当前分支带 *。
        let localOut = try GitProcessRunner.run(
            ["for-each-ref", "refs/heads", "--format=%(refname:short)"],
            in: repository
        )
        var localNames = localOut
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // 移除 * 前缀（for-each-ref 不带 *，branch --show-current 用于判断当前分支）。
        localNames.removeAll { $0 == "*" }
        let current = GitRefReader.currentBranch(in: repository)

        var result = localNames.map {
            GitBranchSummary(name: String($0), isRemote: false, isCurrent: $0 == current)
        }

        // 远程分支：`git for-each-ref refs/remotes --format=%(refname:short)`，排除 origin/HEAD。
        if let remoteOut = try? GitProcessRunner.run(
            ["for-each-ref", "refs/remotes", "--format=%(refname:short)"],
            in: repository
        ) {
            let remoteNames = remoteOut
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasSuffix("/HEAD") }
            result += remoteNames.map {
                GitBranchSummary(name: String($0), isRemote: true, isCurrent: false)
            }
        }
        return result
    }

    /// 新建分支。
    public static func createBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["branch", name], in: repository)
    }

    /// 切换分支。
    public static func checkoutBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["checkout", name], in: repository)
    }

    /// 删除本地分支（-d 保守删除，仅已合并分支）。
    public static func deleteBranch(named name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["branch", "-d", name], in: repository)
    }

    /// 重命名本地分支。
    public static func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {
        let current = try validatedBranchName(currentName, in: repository)
        let new = try validatedBranchName(newName, in: repository)
        do {
            _ = try GitProcessRunner.run(["branch", "-m", current, new], in: repository)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.renameFailed(Self.message(for: error))
        }
    }

    /// 为本地分支设置远程上游分支，例如 `origin/main`。
    public static func setUpstream(
        localBranch: String,
        upstreamBranch: String,
        in repository: URL
    ) throws {
        let local = try validatedBranchName(localBranch, in: repository)
        let upstream = try validatedBranchName(upstreamBranch, in: repository)
        do {
            _ = try GitProcessRunner.run(
                ["branch", "--set-upstream-to=\(upstream)", local],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.upstreamFailed(Self.message(for: error))
        }
    }

    /// 清除本地分支的远程上游配置。
    public static func unsetUpstream(localBranch: String, in repository: URL) throws {
        let local = try validatedBranchName(localBranch, in: repository)
        do {
            _ = try GitProcessRunner.run(["branch", "--unset-upstream", local], in: repository)
        } catch let error as Error {
            throw error
        } catch {
            throw Error.upstreamFailed(Self.message(for: error))
        }
    }

    /// 将本地分支发布到远程并设置 upstream。
    public static func publishBranch(
        localBranch: String,
        remote: String = "origin",
        remoteBranch: String? = nil,
        in repository: URL
    ) throws {
        let local = try validatedBranchName(localBranch, in: repository)
        let remoteName = try validatedRemoteName(remote)
        let target = try validatedBranchName(remoteBranch ?? local, in: repository)
        do {
            _ = try GitProcessRunner.run(
                ["push", "--set-upstream", remoteName, "\(local):\(target)"],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.publishFailed(Self.message(for: error))
        }
    }

    /// 删除远程分支。`branchName` 可传 `origin/topic` 或 `topic`。
    public static func deleteRemoteBranch(
        named branchName: String,
        remote: String = "origin",
        in repository: URL
    ) throws {
        let name = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw Error.invalidBranchName }
        let remoteName = try validatedRemoteName(remote)
        let prefix = "\(remoteName)/"
        let shortName = name.hasPrefix(prefix) ? String(name.dropFirst(prefix.count)) : name
        guard !shortName.isEmpty, shortName != "HEAD" else {
            throw Error.cannotDeleteRemoteHead
        }
        _ = try validatedBranchName(shortName, in: repository)

        do {
            _ = try GitProcessRunner.run(
                ["push", remoteName, "--delete", "refs/heads/\(shortName)"],
                in: repository
            )
        } catch let error as Error {
            throw error
        } catch {
            throw Error.deleteRemoteFailed(Self.message(for: error))
        }
    }

    /// 比较两个分支的 ahead/behind、提交和文件差异。
    public static func compareBranches(
        base: String,
        head: String,
        in repository: URL
    ) throws -> GitBranchCompare {
        try GitBranchCompareOperation.compare(base: base, head: head, in: repository)
    }

    private static func validatedBranchName(_ name: String, in repository: URL) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidBranchName }
        do {
            _ = try GitProcessRunner.run(["check-ref-format", "--branch", trimmed], in: repository)
        } catch {
            throw Error.invalidBranchName
        }
        return trimmed
    }

    private static func validatedRemoteName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Error.invalidRemoteName }
        return trimmed
    }

    private static func message(for error: Swift.Error) -> String {
        (error as? GitProcessRunner.Error)?.errorDescription ?? error.localizedDescription
    }
}
