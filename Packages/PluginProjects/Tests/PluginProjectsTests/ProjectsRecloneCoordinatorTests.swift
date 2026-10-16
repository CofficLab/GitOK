import Foundation
import KitGit
import LumiLocalizationKit
import ProviderCloneRepository
import ProviderProjects
import Testing
@testable import PluginProjects

// MARK: - Test Doubles

/// `GitRemoteCapability` 替身：只实现 remote 解析这一个成员。
@MainActor
private final class StubRemoteCapability: GitRemoteCapability {
    var remotes: [GitRemoteSummary] = []

    func listRemotes(in repositoryURL: URL) -> [GitRemoteSummary] { remotes }
}

/// `ProjectCloneCapability` 替身：可控任务状态与注入错误。
@MainActor
private final class StubCloneCapability: ProjectCloneCapability {
    var tasks: [CloneTask] = []
    var enqueueError: Error?
    var validationError: Error?

    private(set) var validatedDestinations: [URL] = []
    private(set) var enqueuedRemoteURLs: [String] = []

    func validateDestination(_ url: URL) throws {
        validatedDestinations.append(url)
        if let validationError { throw validationError }
    }

    func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask {
        if let enqueueError { throw enqueueError }
        enqueuedRemoteURLs.append(remoteURL)
        let task = CloneTask(
            remoteURL: remoteURL,
            destination: destination,
            repositoryName: repositoryName,
            status: .queued
        )
        tasks = [task]
        return task
    }

    /// 测试辅助：推进指定任务到终态。
    func complete(_ taskID: UUID, status: CloneTaskStatus, errorMessage: String? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        var task = tasks[index]
        task.status = status
        task.errorMessage = errorMessage
        tasks[index] = task
    }
}

// MARK: - Fixtures

@MainActor
private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ProjectsRecloneTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor
private func makeProject(at url: URL) -> Project {
    Project(id: UUID(), url: url, title: "Demo", isPinned: false)
}

/// 已注册 origin remote 的协调器，这是绝大多数用例的起点。
@MainActor
private func makeCoordinator(
    remoteURL: String = "https://example.com/r.git"
) -> (ProjectsRecloneCoordinator, StubCloneCapability) {
    let remote = StubRemoteCapability()
    remote.remotes = [GitRemoteSummary(name: "origin", url: remoteURL, fetchURL: nil)]
    let clone = StubCloneCapability()
    return (ProjectsRecloneCoordinator(git: remote, clone: clone), clone)
}

// MARK: - Preparation

@Suite("ProjectsRecloneCoordinator preparation")
@MainActor
struct ReclonePreparationTests {

    @Test("prepare resolves origin remote and enters confirming state")
    func prepareResolvesOrigin() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let remote = StubRemoteCapability()
        remote.remotes = [
            GitRemoteSummary(name: "upstream", url: "https://example.com/upstream.git", fetchURL: nil),
            GitRemoteSummary(name: "origin", url: "https://example.com/fallback.git", fetchURL: "https://example.com/origin.git"),
        ]
        let coordinator = ProjectsRecloneCoordinator(git: remote, clone: StubCloneCapability())

        try coordinator.prepare(project)

        // fetchURL 优先于 url。
        #expect(coordinator.state == .confirming(
            project: project,
            remoteURL: "https://example.com/origin.git"
        ))
        #expect(!coordinator.isRunning)
    }

    @Test("prepare falls back to the first remote when origin is absent")
    func prepareFallsBackToFirstRemote() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let remote = StubRemoteCapability()
        remote.remotes = [
            GitRemoteSummary(name: "fork", url: "https://example.com/fork.git", fetchURL: nil),
        ]
        let coordinator = ProjectsRecloneCoordinator(git: remote, clone: StubCloneCapability())

        try coordinator.prepare(project)

        #expect(coordinator.state == .confirming(
            project: project,
            remoteURL: "https://example.com/fork.git"
        ))
    }

    @Test("prepare throws noRemote when the project has no remote")
    func prepareThrowsWithoutRemote() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let remote = StubRemoteCapability()
        remote.remotes = []
        let coordinator = ProjectsRecloneCoordinator(git: remote, clone: StubCloneCapability())

        #expect(throws: RecloneError.noRemote) { try coordinator.prepare(project) }
        #expect(coordinator.state == .idle)
    }

    @Test("prepare throws noRemote when the remote URL is blank")
    func prepareThrowsOnBlankRemote() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let remote = StubRemoteCapability()
        remote.remotes = [GitRemoteSummary(name: "origin", url: "   ", fetchURL: nil)]
        let coordinator = ProjectsRecloneCoordinator(git: remote, clone: StubCloneCapability())

        #expect(throws: RecloneError.noRemote) { try coordinator.prepare(project) }
    }

    @Test("prepare refuses to target the home directory")
    func prepareRefusesHomeDirectory() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let project = makeProject(at: home)
        let (coordinator, _) = makeCoordinator()

        #expect(throws: RecloneError.unsafeTarget) { try coordinator.prepare(project) }
    }

    @Test("prepare refuses to target the filesystem root")
    func prepareRefusesRootDirectory() throws {
        let project = makeProject(at: URL(fileURLWithPath: "/", isDirectory: true))
        let (coordinator, _) = makeCoordinator()

        #expect(throws: RecloneError.unsafeTarget) { try coordinator.prepare(project) }
    }

    @Test("prepare is ignored while a re-clone is running")
    func prepareIgnoredWhileRunning() throws {
        let root = try makeTemporaryDirectory()
        let first = makeProject(at: root.appendingPathComponent("first", isDirectory: true))
        let second = makeProject(at: root.appendingPathComponent("second", isDirectory: true))
        let (coordinator, _) = makeCoordinator()

        try coordinator.prepare(first)
        coordinator.beginReclone()
        try coordinator.prepare(second)

        #expect(coordinator.isRunning)
    }
}

// MARK: - Confirmation Lifecycle

@Suite("ProjectsRecloneCoordinator confirmation lifecycle")
@MainActor
struct RecloneConfirmationTests {

    @Test("cancelConfirmation returns to idle")
    func cancelReturnsToIdle() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, _) = makeCoordinator()

        try coordinator.prepare(project)
        coordinator.cancelConfirmation()

        #expect(coordinator.state == .idle)
    }

    @Test("dismissFailure returns to idle")
    func dismissFailureReturnsToIdle() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()
        clone.enqueueError = RecloneTestError.enqueueFailed

        try coordinator.prepare(project)
        coordinator.beginReclone()
        #expect(coordinator.state == .failed(message: "enqueue failed"))

        coordinator.dismissFailure()
        #expect(coordinator.state == .idle)
    }

    @Test("beginReclone is a no-op when not confirming")
    func beginWithoutConfirmationIsNoOp() {
        let (coordinator, clone) = makeCoordinator()

        coordinator.beginReclone()

        #expect(coordinator.state == .idle)
        #expect(clone.enqueuedRemoteURLs.isEmpty)
    }

    @Test("beginReclone is a no-op when already running")
    func beginWhileRunningIsNoOp() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()

        try coordinator.prepare(project)
        coordinator.beginReclone()
        coordinator.beginReclone()

        // 第二次调用不应重复入队。
        #expect(clone.enqueuedRemoteURLs.count == 1)
    }
}

// MARK: - Execution

@Suite("ProjectsRecloneCoordinator execution")
@MainActor
struct RecloneExecutionTests {

    @Test("beginReclone enqueues into a sibling temporary directory and enters running")
    func beginRecloneEnqueuesSiblingDirectory() throws {
        let root = try makeTemporaryDirectory()
        let projectURL = root.appendingPathComponent("demo", isDirectory: true)
        let project = makeProject(at: projectURL)
        let (coordinator, clone) = makeCoordinator(remoteURL: "https://example.com/r.git")

        try coordinator.prepare(project)
        coordinator.beginReclone()

        guard case let .running(taskID) = coordinator.state else {
            Issue.record("expected running state, got \(coordinator.state)")
            return
        }
        #expect(coordinator.isRunning)
        #expect(clone.enqueuedRemoteURLs == ["https://example.com/r.git"])
        #expect(clone.tasks.first?.id == taskID)

        // 目标必须是项目目录的同级兄弟目录，后续 move 才能保持原子性。
        let validated = try #require(clone.validatedDestinations.first)
        #expect(validated.deletingLastPathComponent() == projectURL.deletingLastPathComponent())
        #expect(validated.lastPathComponent.hasPrefix(".gitok-reclone-"))
    }

    @Test("enqueue failure surfaces as failed state")
    func enqueueFailureSurfaces() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()
        clone.enqueueError = RecloneTestError.enqueueFailed

        try coordinator.prepare(project)
        coordinator.beginReclone()

        #expect(coordinator.state == .failed(message: "enqueue failed"))
        #expect(!coordinator.isRunning)
    }

    @Test("validation failure prevents enqueue")
    func validationFailurePreventsEnqueue() throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()
        clone.validationError = RecloneTestError.invalidDestination

        try coordinator.prepare(project)
        coordinator.beginReclone()

        #expect(coordinator.state == .failed(message: "invalid destination"))
        #expect(clone.enqueuedRemoteURLs.isEmpty)
    }

    @Test("completed task replaces the project directory and reports back")
    func completedTaskReplacesDirectory() async throws {
        let root = try makeTemporaryDirectory()
        let projectURL = root.appendingPathComponent("demo", isDirectory: true)
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try "old".write(
            to: projectURL.appendingPathComponent("marker.txt"),
            atomically: true, encoding: .utf8
        )

        let project = makeProject(at: projectURL)
        let remote = StubRemoteCapability()
        remote.remotes = [GitRemoteSummary(name: "origin", url: "https://example.com/r.git", fetchURL: nil)]
        let clone = StubCloneCapability()
        var replaced = false
        let coordinator = ProjectsRecloneCoordinator(
            git: remote,
            clone: clone,
            onProjectReplaced: { replaced = true }
        )

        try coordinator.prepare(project)
        coordinator.beginReclone()

        guard case let .running(taskID) = coordinator.state else {
            Issue.record("expected running state")
            return
        }

        // 模拟后台任务完成：先把克隆产物落到临时目录，再标记任务完成。
        let clonedDirectory = try #require(clone.tasks.first?.destination)
        try FileManager.default.createDirectory(at: clonedDirectory, withIntermediateDirectories: true)
        try "new".write(
            to: clonedDirectory.appendingPathComponent("marker.txt"),
            atomically: true, encoding: .utf8
        )
        clone.complete(taskID, status: .completed)

        await coordinator.run(taskID: taskID)

        #expect(coordinator.state == .idle)
        #expect(replaced)

        let marker = try String(
            contentsOf: projectURL.appendingPathComponent("marker.txt"),
            encoding: .utf8
        )
        #expect(marker == "new")

        // 临时目录与备份目录都不应残留。
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix(".gitok-reclone-") }
        #expect(leftovers.isEmpty)
    }

    @Test("failed task cleans up the temporary directory and reports the error")
    func failedTaskCleansUp() async throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()

        try coordinator.prepare(project)
        coordinator.beginReclone()

        guard case let .running(taskID) = coordinator.state else {
            Issue.record("expected running state")
            return
        }
        let clonedDirectory = try #require(clone.tasks.first?.destination)
        try FileManager.default.createDirectory(at: clonedDirectory, withIntermediateDirectories: true)

        clone.complete(taskID, status: .failed, errorMessage: "remote unreachable")
        await coordinator.run(taskID: taskID)

        #expect(coordinator.state == .failed(message: "remote unreachable"))
        #expect(!FileManager.default.fileExists(atPath: clonedDirectory.path))
    }

    @Test("cancelled task falls back to a localized failure message")
    func cancelledTaskUsesFallbackMessage() async throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()

        try coordinator.prepare(project)
        coordinator.beginReclone()

        guard case let .running(taskID) = coordinator.state else {
            Issue.record("expected running state")
            return
        }
        let clonedDirectory = try #require(clone.tasks.first?.destination)
        try FileManager.default.createDirectory(at: clonedDirectory, withIntermediateDirectories: true)

        clone.complete(taskID, status: .cancelled)
        await coordinator.run(taskID: taskID)

        guard case let .failed(message) = coordinator.state else {
            Issue.record("expected failed state, got \(coordinator.state)")
            return
        }
        #expect(message == PluginLocalization(bundle: .module).string("Re-clone Failed"))
    }

    @Test("run ignores a stale task ID")
    func runIgnoresStaleTaskID() async {
        let (coordinator, _) = makeCoordinator()

        await coordinator.run(taskID: UUID())

        #expect(coordinator.state == .idle)
    }

    @Test("run returns immediately when the tracked task disappears")
    func runReturnsWhenTaskDisappears() async throws {
        let root = try makeTemporaryDirectory()
        let project = makeProject(at: root.appendingPathComponent("demo"))
        let (coordinator, clone) = makeCoordinator()

        try coordinator.prepare(project)
        coordinator.beginReclone()

        guard case let .running(taskID) = coordinator.state else {
            Issue.record("expected running state")
            return
        }

        // 任务被外部清理：轮询必须终止而不是无限空转。
        clone.tasks = []
        await coordinator.run(taskID: taskID)

        #expect(coordinator.state == .running(taskID: taskID))
    }
}

// MARK: - Directory Replacement

@Suite("ProjectsRecloneCoordinator directory replacement")
struct ReplaceProjectDirectoryTests {

    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReplaceDir-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func marker(in directory: URL) throws -> String {
        try String(
            contentsOf: directory.appendingPathComponent("marker.txt"),
            encoding: .utf8
        )
    }

    private func leftovers(in root: URL, prefix: String) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix(prefix) }
    }

    @Test("replaces an existing directory and removes the backup")
    func replacesExistingDirectory() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectURL = root.appendingPathComponent("demo", isDirectory: true)
        let clonedURL = root.appendingPathComponent("fresh", isDirectory: true)
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: clonedURL, withIntermediateDirectories: true)
        try "old".write(
            to: projectURL.appendingPathComponent("marker.txt"),
            atomically: true, encoding: .utf8
        )
        try "new".write(
            to: clonedURL.appendingPathComponent("marker.txt"),
            atomically: true, encoding: .utf8
        )

        try ProjectsRecloneCoordinator.replaceProjectDirectory(with: clonedURL, at: projectURL)

        #expect(try marker(in: projectURL) == "new")
        #expect(!FileManager.default.fileExists(atPath: clonedURL.path))
        #expect(try leftovers(in: root, prefix: ".gitok-reclone-backup-").isEmpty)
    }

    @Test("restores the original directory when the move fails")
    func restoresOriginalOnFailure() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectURL = root.appendingPathComponent("demo", isDirectory: true)
        // clonedURL 故意不存在，第二次 move 必然失败以触发回滚。
        let missingURL = root.appendingPathComponent("does-not-exist", isDirectory: true)
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try "old".write(
            to: projectURL.appendingPathComponent("marker.txt"),
            atomically: true, encoding: .utf8
        )

        #expect(throws: (any Error).self) {
            try ProjectsRecloneCoordinator.replaceProjectDirectory(
                with: missingURL,
                at: projectURL
            )
        }

        // 回滚后原目录必须完好无损，且不留备份残留。
        #expect(try marker(in: projectURL) == "old")
        #expect(try leftovers(in: root, prefix: ".gitok-reclone-backup-").isEmpty)
    }

    @Test("materializes a missing project directory")
    func materializesMissingDirectory() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let projectURL = root.appendingPathComponent("demo", isDirectory: true)
        let clonedURL = root.appendingPathComponent("fresh", isDirectory: true)
        try FileManager.default.createDirectory(at: clonedURL, withIntermediateDirectories: true)

        try ProjectsRecloneCoordinator.replaceProjectDirectory(with: clonedURL, at: projectURL)

        #expect(FileManager.default.fileExists(atPath: projectURL.path))
    }
}

// MARK: - Errors

private enum RecloneTestError: LocalizedError {
    case enqueueFailed
    case invalidDestination

    var errorDescription: String? {
        switch self {
        case .enqueueFailed: "enqueue failed"
        case .invalidDestination: "invalid destination"
        }
    }
}