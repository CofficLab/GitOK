import Foundation
import KitGit

/// Git 后端的展示信息。
public struct GitBackendDescriptor: Equatable, Identifiable, Sendable {
    public let id: String
    public let pluginID: String
    public let name: String
    public let version: String
    public let priority: Int

    public init(
        id: String,
        pluginID: String,
        name: String,
        version: String = "1.0.0",
        priority: Int = 0
    ) {
        self.id = id
        self.pluginID = pluginID
        self.name = name
        self.version = version
        self.priority = priority
    }
}

/// GitOK 内置后端目录。
///
/// 目录只用于稳定标识和默认优先级，不代表用户可选择后端。
public enum GitBackendCatalog {
    public static let cli = GitBackendDescriptor(
        id: "com.coffic.gitok.git-backend.cli",
        pluginID: "com.coffic.gitok.plugin.git-cli",
        name: "Git CLI",
        version: "1.0.0",
        priority: 100
    )

    public static let libGit2 = GitBackendDescriptor(
        id: "com.coffic.gitok.git-backend.libgit2",
        pluginID: "com.coffic.gitok.plugin.git-libgit2",
        name: "LibGit2Swift",
        version: "7005a738",
        priority: 50
    )

    public static let all: [GitBackendDescriptor] = [cli, libGit2]
}

/// Git Provider 的错误。
public enum GitProviderError: Error, LocalizedError, Equatable, Sendable {
    case noBackendAvailable
    case backendAlreadyRegistered(String)
    case backendOperationUnsupported(String)
    case allBackendsFailed(operation: String, failures: [GitBackendFailure])

    public struct GitBackendFailure: Equatable, Sendable {
        public let backendID: String
        public let backendName: String
        public let message: String

        public init(backendID: String, backendName: String, message: String) {
            self.backendID = backendID
            self.backendName = backendName
            self.message = message
        }
    }

    public var errorDescription: String? {
        switch self {
        case .noBackendAvailable:
            return "No Git backend is available."
        case .backendAlreadyRegistered(let id):
            return "Git backend is already registered: \(id)"
        case .backendOperationUnsupported(let message):
            return message
        case .allBackendsFailed(let operation, let failures):
            let details = failures
                .map { "\($0.backendName): \($0.message)" }
                .joined(separator: "\n")
            return "Git operation failed (\(operation)).\n\(details)"
        }
    }
}

/// Git 操作能力边界。
///
/// 业务插件只依赖这个协议，不再直接依赖 CLI 或 LibGit2。当前先覆盖
/// 现有 GitOK 中最常用的读取、提交、分支、远程和合并能力；后续能力继续
/// 以同一协议扩展，模型仍复用 KitGit 的公共值类型。
public protocol GitOperationProviding: AnyObject, Sendable {
    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit]
    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit]
    func countCommits(in repository: URL) throws -> Int
    func unpushedCommitHashes(in repository: URL) throws -> Set<String>

    func loadStatus(in repository: URL) throws -> GitWorktreeStatus
    func loadEntries(in repository: URL) throws -> [GitStatusEntry]
    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange]
    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int
    func loadCommitChangesPage(
        commit hash: String,
        limit: Int,
        offset: Int,
        in repository: URL
    ) throws -> GitFileChangePage
    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String
    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String

    func currentBranch(in repository: URL) -> String?
    func latestTag(in repository: URL) -> String?
    func firstCommitDate(in repository: URL) -> Date?
    func unpushedCount(in repository: URL) -> Int?
    func hasRemotes(in repository: URL) -> Bool
    func unpulledCount(in repository: URL) -> Int?
    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus

    func listBranches(in repository: URL) throws -> [GitBranchSummary]
    func createBranch(named name: String, in repository: URL) throws
    func checkoutBranch(named name: String, in repository: URL) throws
    func deleteBranch(named name: String, in repository: URL) throws
    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws
    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws
    func unsetUpstream(localBranch: String, in repository: URL) throws
    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws
    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws
    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare

    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String
    func revertCommit(_ commitHash: String, in repository: URL) throws -> String
    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String
    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String
    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String
    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String

    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String
    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String
    func deleteLocalTag(named name: String, in repository: URL) throws -> String
    func pushTag(named name: String, remote: String, in repository: URL) throws -> String
    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String

    func listStashes(in repository: URL) -> [GitStashEntry]
    func hasChangesToStash(in repository: URL) -> Bool
    func saveStash(message: String?, in repository: URL) throws
    func applyStash(_ entry: GitStashEntry, in repository: URL) throws
    func popStash(_ entry: GitStashEntry, in repository: URL) throws
    func dropStash(_ entry: GitStashEntry, in repository: URL) throws

    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus
    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String
    func continueCherryPick(in repository: URL) throws -> String
    func abortCherryPick(in repository: URL) throws -> String

    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary]
    func updateSubmodules(in repository: URL) throws

    func validateCloneDestination(_ destination: URL) throws
    func defaultRepositoryName(from remoteURL: String) -> String?
    func clone(remoteURL: String, destination: URL) throws -> URL
    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void
    ) throws -> URL
    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL

    func hasStagedChanges(in repository: URL) throws -> Bool
    func addAll(in repository: URL) throws
    func stageFiles(_ filePaths: [String], in repository: URL) throws
    func unstageFiles(_ filePaths: [String], in repository: URL) throws
    func discardFileChanges(_ filePath: String, in repository: URL) throws
    func discardFiles(_ filePaths: [String], in repository: URL) throws
    func discardAllChanges(in repository: URL) throws
    func commit(message: String, in repository: URL) throws -> String
    func push(in repository: URL) throws -> String

    func listRemotes(in repository: URL) -> [GitRemoteSummary]
    func addRemote(name: String, url: String, in repository: URL) throws
    func removeRemote(name: String, in repository: URL) throws
    func fetch(in repository: URL) throws
    func pull(in repository: URL) throws
    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws
    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus
    func webLink(for url: String) -> URL?

    func isMerging(in repository: URL) -> Bool
    func hasConflictOperation(in repository: URL) -> Bool
    func conflictFiles(in repository: URL) -> [String]
    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String
    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String
    func mergeFileDiff(path: String, in repository: URL) throws -> String
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws
    func continueMerge(in repository: URL) throws -> String
    func abortMerge(in repository: URL) throws -> String
    func finalizeMergeIfNeeded(in repository: URL) throws -> String?
}

public extension GitOperationProviding {
    /// 默认兼容实现：没有原生进度支持的后端仍提供开始 / 完成状态。
    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void
    ) throws -> URL {
        try clone(
            remoteURL: remoteURL,
            destination: destination,
            progress: progress,
            cancellation: nil
        )
    }

    func clone(
        remoteURL: String,
        destination: URL,
        progress: @escaping @Sendable (GitCloneProgress) -> Void,
        cancellation: GitProcessCancellation?
    ) throws -> URL {
        progress(.init(phase: .preparing))
        if cancellation?.isCancelled == true {
            throw CancellationError()
        }
        let result = try clone(remoteURL: remoteURL, destination: destination)
        if cancellation?.isCancelled == true {
            throw CancellationError()
        }
        progress(.init(phase: .completed, fractionCompleted: 1))
        return result
    }
}

/// 一个可被插件装配的 Git 实现。
public protocol GitBackendProviding: GitOperationProviding {
    var descriptor: GitBackendDescriptor { get }
    /// 后端初始化完成但当前环境不可用时，路由器会跳过该后端。
    var isAvailable: Bool { get }
}

public extension GitBackendProviding {
    var isAvailable: Bool { true }
}

/// 后端注册与选择能力。宿主只注册一个稳定的 GitProviding 路由器，
/// 各后端插件通过此接口加入或撤出，不会互相抢占同一个 Provider 类型。
public protocol GitBackendRegistryProviding: AnyObject {
    var availableBackends: [GitBackendDescriptor] { get }

    func registerBackend(_ backend: any GitBackendProviding) throws
    func unregisterBackend(id: String)
}

/// 业务插件消费的稳定 Git Provider。
public protocol GitProviding: GitOperationProviding, GitBackendRegistryProviding {}
