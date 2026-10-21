import Foundation
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import Testing
@testable import PluginGitBranchStatus

// MARK: - Test doubles

/// 记录每次 `currentBranch` 读取所使用的取消句柄，用于断言「旧任务被取消」。
private final class BranchReadRecord: @unchecked Sendable {
    let lock = NSLock()
    private var cancellations: [GitProcessCancellation] = []
    private var startedCount = 0

    /// 读取在取消发生前保持阻塞，用于让「在途读取」状态可被断言。
    var blocksUntilCancelled = false

    /// 每次读取登记的取消句柄（按读取顺序）。
    var recordedCancellations: [GitProcessCancellation] {
        lock.lock()
        defer { lock.unlock() }
        return cancellations
    }

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return startedCount
    }

    /// 记录一次读取；若要求阻塞，则等到该读取被取消后再返回。
    func record(_ cancellation: GitProcessCancellation?) {
        let shouldBlock: Bool = {
            lock.lock()
            defer { lock.unlock() }
            startedCount += 1
            if let cancellation { cancellations.append(cancellation) }
            return blocksUntilCancelled
        }()

        guard shouldBlock, let cancellation else { return }
        // 模拟一个真正卡住的 git 子进程：只有被取消才会结束。
        let deadline = Date().addingTimeInterval(5)
        while !cancellation.isCancelled, Date() < deadline {
            usleep(1_000)
        }
    }
}

/// `GitProviding` 测试替身：只实现分支读取，其余操作返回空值。
private final class StubGit: GitProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: any GitBackendProviding] = [:]
    let records = BranchReadRecord()

    /// 分支读取结果。
    var branchValue: String?

    /// 读取被取消时返回 `true`。
    var respectsCancellation = false

    var availableBackends: [GitBackendDescriptor] { [] }

    func registerBackend(_ backend: any GitBackendProviding) throws {
        lock.lock(); defer { lock.unlock() }
        storage[backend.descriptor.id] = backend
    }

    func unregisterBackend(id: String) {
        lock.lock(); defer { lock.unlock() }
        storage[id] = nil
    }

    func currentBranch(in repository: URL) -> String? {
        currentBranch(in: repository, cancellation: nil)
    }

    func currentBranch(
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) -> String? {
        records.record(cancellation)
        guard !respectsCancellation else {
            return cancellation?.isCancelled == true ? nil : branchValue
        }
        return branchValue
    }

    func loadCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] { [] }
    func loadAllCommits(in repository: URL, limit: Int, offset: Int) throws -> [GitCommit] { [] }
    func countCommits(in repository: URL) throws -> Int { 0 }
    func unpushedCommitHashes(in repository: URL) throws -> Set<String> { [] }
    func loadStatus(in repository: URL) throws -> GitWorktreeStatus {
        GitWorktreeStatus(isClean: true, changeCount: 0, branch: nil)
    }
    func loadEntries(in repository: URL) throws -> [GitStatusEntry] { [] }
    func loadWorktreeSnapshot(in repository: URL) throws -> GitWorktreeSnapshot {
        GitWorktreeSnapshot(entries: [], branch: nil)
    }
    func cachedWorktreeSnapshot(in repository: URL) -> GitWorktreeSnapshot? { nil }
    func invalidateWorktreeSnapshot(in repository: URL) {}
    func loadChanges(commit hash: String, in repository: URL) throws -> [GitFileChange] { [] }
    func countCommitChanges(commit hash: String, in repository: URL) throws -> Int { 0 }
    func loadCommitChangesPage(commit hash: String, limit: Int, offset: Int, in repository: URL) throws -> GitFileChangePage {
        GitFileChangePage(offset: offset, changes: [], hasMore: false)
    }
    func loadDiff(commit hash: String, filePath: String, in repository: URL) throws -> String { "" }
    func loadWorktreeDiff(filePath: String, in repository: URL) throws -> String { "" }
    func loadBlobData(commit: String, filePath: String, in repository: URL) throws -> Data { Data() }
    func loadWorktreeFileData(filePath: String, in repository: URL) throws -> Data { Data() }
    func latestTag(in repository: URL) -> String? { nil }
    func firstCommitDate(in repository: URL) -> Date? { nil }
    func unpushedCount(in repository: URL) -> Int? { 0 }
    func unpushedCount(in repository: URL, cancellation: GitProcessCancellation?) -> Int? { 0 }
    func hasRemotes(in repository: URL) -> Bool { false }
    func unpulledCount(in repository: URL) -> Int? { nil }
    func remoteTrackingStatus(in repository: URL) -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }
    func listBranches(in repository: URL) throws -> [GitBranchSummary] { [] }
    func createBranch(named name: String, in repository: URL) throws {}
    func checkoutBranch(named name: String, in repository: URL) throws {}
    func checkoutRemoteBranch(named remoteBranch: String, as localBranch: String?, in repository: URL) throws {}
    func deleteBranch(named name: String, in repository: URL) throws {}
    func renameBranch(from currentName: String, to newName: String, in repository: URL) throws {}
    func setUpstream(localBranch: String, upstreamBranch: String, in repository: URL) throws {}
    func unsetUpstream(localBranch: String, in repository: URL) throws {}
    func publishBranch(localBranch: String, remote: String, remoteBranch: String?, in repository: URL) throws {}
    func deleteRemoteBranch(named branchName: String, remote: String, in repository: URL) throws {}
    func compareBranches(base: String, head: String, in repository: URL) throws -> GitBranchCompare {
        GitBranchCompare(base: base, head: head, ahead: 0, behind: 0, commits: [], files: [])
    }
    func undoCommit(_ commitHash: String, parentHash: String, in repository: URL) throws -> String { "" }
    func revertCommit(_ commitHash: String, in repository: URL) throws -> String { "" }
    func softReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func mixedReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func hardReset(to targetHash: String, expectedHead: String, in repository: URL) throws -> String { "" }
    func squash(to targetHash: String, parentHash: String, expectedHead: String, message: String, in repository: URL) throws -> String { "" }
    func createLightweightTag(named name: String, at commitHash: String, in repository: URL) throws -> String { "" }
    func createAnnotatedTag(named name: String, at commitHash: String, message: String, in repository: URL) throws -> String { "" }
    func deleteLocalTag(named name: String, in repository: URL) throws -> String { "" }
    func pushTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func deleteRemoteTag(named name: String, remote: String, in repository: URL) throws -> String { "" }
    func listStashes(in repository: URL) -> [GitStashEntry] { [] }
    func hasChangesToStash(in repository: URL) -> Bool { false }
    func saveStash(message: String?, in repository: URL) throws {}
    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func popStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {}
    func cherryPickStatus(in repository: URL) -> GitCherryPickStatus { .inactive }
    func cherryPick(commits: [String], onto branch: String?, in repository: URL) throws -> String { "" }
    func continueCherryPick(in repository: URL) throws -> String { "" }
    func abortCherryPick(in repository: URL) throws -> String { "" }
    func listSubmodules(in repository: URL) -> [GitSubmoduleSummary] { [] }
    func updateSubmodules(in repository: URL) throws {}
    func validateCloneDestination(_ destination: URL) throws {}
    func defaultRepositoryName(from remoteURL: String) -> String? { nil }
    func clone(remoteURL: String, destination: URL) throws -> URL { destination }
    func hasStagedChanges(in repository: URL) throws -> Bool { false }
    func addAll(in repository: URL) throws {}
    func stageFiles(_ filePaths: [String], in repository: URL) throws {}
    func unstageFiles(_ filePaths: [String], in repository: URL) throws {}
    func discardFileChanges(_ filePath: String, in repository: URL) throws {}
    func discardFiles(_ filePaths: [String], in repository: URL) throws {}
    func discardAllChanges(in repository: URL) throws {}
    func commit(message: String, in repository: URL) throws -> String { "" }
    func push(in repository: URL) throws -> String { "" }
    func listRemotes(in repository: URL) -> [GitRemoteSummary] { [] }
    func addRemote(name: String, url: String, in repository: URL) throws {}
    func removeRemote(name: String, in repository: URL) throws {}
    func fetch(in repository: URL) throws {}
    func pull(in repository: URL) throws {}
    func pull(in repository: URL, strategy: GitRemoteOperation.PullStrategy) throws {}
    func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    }
    func webLink(for url: String) -> URL? { nil }
    func isMerging(in repository: URL) -> Bool { false }
    func hasConflictOperation(in repository: URL) -> Bool { false }
    func conflictFiles(in repository: URL) -> [String] { [] }
    func mergeBranches(repository: URL, sourceBranch: String, targetBranch: String) throws -> String { "" }
    func mergeFileContent(path: String, version: GitMergeFileVersion, in repository: URL) throws -> String { "" }
    func mergeFileDiff(path: String, in repository: URL) throws -> String { "" }
    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion, in repository: URL) throws {}
    func continueMerge(in repository: URL) throws -> String { "" }
    func abortMerge(in repository: URL) throws -> String { "" }
    func finalizeMergeIfNeeded(in repository: URL) throws -> String? { nil }
}

/// 项目事件源：记录订阅者，可手动派发事件。
@MainActor
private final class StubProjects: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?
    private var callbacks: [UUID: (ProjectProvidingEvent) -> Void] = [:]

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        let token = UUID()
        callbacks[token] = callback
        return ProjectHandle { [weak self] in
            self?.callbacks[token] = nil
        }
    }

    func emit(_ event: ProjectProvidingEvent) {
        callbacks.values.forEach { $0(event) }
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func setCurrentProject(id: UUID?) {}
    func selectCommit(_ commit: GitCommit) { currentCommit = commit }
    func selectFile(_ file: String?) { currentFile = file }
    func clearCommitSelection() { currentCommit = nil; currentFile = nil }
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
private final class ProjectHandle: ProjectProvidingObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) { self.cancelAction = cancel }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

/// 仓库监听事件源。
@MainActor
private final class StubRepositoryWatch: GitRepositoryWatching {
    private var callbacks: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
    private(set) var watchingRepositoryURL: URL?

    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let token = UUID()
        callbacks[token] = callback
        return RepositoryHandle { [weak self] in
            self?.callbacks[token] = nil
        }
    }

    func emit(_ event: GitRepositoryWatchingEvent) {
        callbacks.values.forEach { $0(event) }
    }

    func startWatching(repositoryURL: URL) {
        watchingRepositoryURL = repositoryURL
        emit(.started(repositoryURL: repositoryURL))
    }

    func stopWatching() {
        watchingRepositoryURL = nil
        emit(.stopped)
    }
}

@MainActor
private final class RepositoryHandle: GitRepositoryWatchingObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) { self.cancelAction = cancel }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

// MARK: - Tests

@Suite("GitBranchStatusObserver")
@MainActor
struct GitBranchStatusObserverTests {

    /// 构造一个可用的临时仓库目录（observer 要求路径在磁盘上存在）。
    private func makeRepositoryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-branch-observer-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    /// 轮询等待条件成立：分支读取跑在 detached task 上，完成时机不由测试控制。
    @discardableResult
    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    @Test("重新加载会取消上一次仍在进行中的分支读取")
    func reloadCancelsPreviousBranchRead() async throws {
        let repositoryURL = try makeRepositoryDirectory()
        defer { try? FileManager.default.removeItem(at: repositoryURL) }

        let projects = StubProjects()
        projects.currentProject = Project(url: repositoryURL)

        let watch = StubRepositoryWatch()
        let git = StubGit()
        git.branchValue = "main"
        // 让读取保持在途，直到被显式取消，才能断言取消行为。
        git.records.blocksUntilCancelled = true

        let viewModel = GitBranchStatusViewModel()
        let observer = GitBranchStatusObserver(
            capability: GitBranchStatusCapabilityAdapter(projects: projects, gitWatch: watch),
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        // 首次读取（init 时触发）跑在 detached task 上，需等待它真正开始。
        await waitUntil { git.records.readCount >= 1 }
        #expect(git.records.readCount == 1)
        let firstCancellation = try #require(git.records.recordedCancellations.first)

        // 触发第二次 reload：第一次的读取必须被取消，
        // 否则旧 git 读取会一直占用线程池，最终让 loading 永远无法结束。
        projects.emit(.dataChanged)

        await waitUntil { git.records.readCount >= 2 }
        #expect(git.records.readCount == 2)
        #expect(firstCancellation.isCancelled, "旧分支读取应在下一次 reload 时被取消")
    }

    @Test("取消 Observer 会取消正在进行的分支读取")
    func cancelObserverCancelsBranchRead() async throws {
        let repositoryURL = try makeRepositoryDirectory()
        defer { try? FileManager.default.removeItem(at: repositoryURL) }

        let projects = StubProjects()
        projects.currentProject = Project(url: repositoryURL)

        let watch = StubRepositoryWatch()
        let git = StubGit()
        git.branchValue = "main"
        // 让读取保持在途，直到被显式取消，才能断言取消行为。
        git.records.blocksUntilCancelled = true

        let viewModel = GitBranchStatusViewModel()
        let observer = GitBranchStatusObserver(
            capability: GitBranchStatusCapabilityAdapter(projects: projects, gitWatch: watch),
            git: git,
            viewModel: viewModel
        )

        await waitUntil { git.records.readCount >= 1 }
        let cancellation = try #require(git.records.recordedCancellations.first)
        observer.cancel()

        #expect(cancellation.isCancelled, "Observer 取消时应终止在途的分支读取")
    }

    @Test("项目切换触发两次事件时只保留一次进行中的分支读取")
    func projectSwitchDoesNotDuplicateInFlightReads() async throws {
        let repositoryURL = try makeRepositoryDirectory()
        defer { try? FileManager.default.removeItem(at: repositoryURL) }

        let projects = StubProjects()
        projects.currentProject = Project(url: repositoryURL)

        let watch = StubRepositoryWatch()
        let git = StubGit()
        git.branchValue = "main"
        // 让读取保持在途，直到被显式取消，才能断言取消行为。
        git.records.blocksUntilCancelled = true

        let viewModel = GitBranchStatusViewModel()
        let observer = GitBranchStatusObserver(
            capability: GitBranchStatusCapabilityAdapter(projects: projects, gitWatch: watch),
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        await waitUntil { git.records.readCount >= 1 }
        let initialReadCount = git.records.readCount

        // 真实场景：切换项目时 `.selectionChanged` 与仓库监听的 `.started`
        // 会连续触发，两次事件指向同一个项目。
        projects.emit(.selectionChanged(projectID: nil))
        watch.emit(.started(repositoryURL: repositoryURL))

        // 等待两次事件各自派发的读取都真正开始。
        await waitUntil { git.records.readCount >= initialReadCount + 2 }
        #expect(git.records.readCount == initialReadCount + 2)

        // 前一次读取必须已被取消，只留下最新一次在途。
        let cancellations = git.records.recordedCancellations
        let inFlight = cancellations.filter { !$0.isCancelled }
        #expect(
            inFlight.count == 1,
            "同一项目的重复事件不应留下多个在途读取，实际在途数：\(inFlight.count)"
        )
    }
}
