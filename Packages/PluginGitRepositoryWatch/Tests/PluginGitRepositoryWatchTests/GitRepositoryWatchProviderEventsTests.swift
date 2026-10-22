import Foundation
import ProviderGitRepositoryWatch
import XCTest
@testable import PluginGitRepositoryWatch

/// `GitRepositoryWatchProvider` 的事件广播覆盖。
///
/// 插件内部用两个 `FSEventStream` 监听器（`.git` 目录 + 工作区根目录）驱动
/// 快照对比与事件广播，本文件用临时构造的 `.git` 目录做端到端验证：
/// - `.git` 监听器没有设置 `kFSEventStreamCreateFlagIgnoreSelf`，测试进程自己
///   写入文件即可触发事件；
/// - 工作区监听器设置了该 flag（忽略本进程产生的事件），因此工作区事件必须
///   由子进程写入文件才能触发。
@MainActor
final class GitRepositoryWatchProviderEventsTests: XCTestCase {

    // MARK: - Helpers

    /// 构造一个只含最小 `.git` 结构的临时仓库。
    private func makeSyntheticRepository() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-watch-repo-\(UUID().uuidString)")
        let gitDir = root.appendingPathComponent(".git")
        try FileManager.default.createDirectory(
            at: gitDir.appendingPathComponent("refs/heads"),
            withIntermediateDirectories: true
        )
        try "ref: refs/heads/main\n".write(
            to: gitDir.appendingPathComponent("HEAD"),
            atomically: true,
            encoding: .utf8
        )
        try "head-hash\n".write(
            to: gitDir.appendingPathComponent("refs/heads/main"),
            atomically: true,
            encoding: .utf8
        )
        return root
    }

    private func removeRepository(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// 等待条件成立；返回是否在超时前成立。
    private func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 40_000_000)
        }
        return condition()
    }

    /// 用子进程写文件：工作区监听器忽略本进程产生的事件。
    private func writeFileFromChildProcess(_ url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/touch")
        process.arguments = [url.path]
        try process.run()
        process.waitUntilExit()
    }

    // MARK: - .git 目录维度

    func testHeadChangeBroadcastsHeadChanged() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        XCTAssertTrue(provider.isWatcherActive)

        try "ref: refs/heads/feature\n".write(
            to: repo.appendingPathComponent(".git/HEAD"),
            atomically: true,
            encoding: .utf8
        )
        try "feature-hash\n".write(
            to: repo.appendingPathComponent(".git/refs/heads/feature"),
            atomically: true,
            encoding: .utf8
        )

        let matched = await waitUntil {
            events.contains { if case .headChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(matched, "应广播 .headChanged，实际事件：\(events)")

        guard case let .headChanged(previousHead, head) = events.first(where: {
            if case .headChanged = $0 { return true } else { return false }
        }) else {
            XCTFail("未找到 .headChanged 事件")
            return
        }
        XCTAssertEqual(previousHead, "head-hash")
        XCTAssertEqual(head, "feature-hash")
    }

    func testIndexChangeBroadcastsIndexChanged() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        try "index-content\n".write(
            to: repo.appendingPathComponent(".git/index"),
            atomically: true,
            encoding: .utf8
        )

        let matched = await waitUntil {
            events.contains { if case .indexChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(matched, "应广播 .indexChanged，实际事件：\(events)")
    }

    func testStashChangeBroadcastsStashChanged() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        try "stash-hash\n".write(
            to: repo.appendingPathComponent(".git/refs/stash"),
            atomically: true,
            encoding: .utf8
        )

        let matched = await waitUntil {
            events.contains { if case .stashChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(matched, "应广播 .stashChanged，实际事件：\(events)")
    }

    func testRefsChangeBroadcastsRefsChanged() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        try "other-hash\n".write(
            to: repo.appendingPathComponent(".git/refs/heads/other"),
            atomically: true,
            encoding: .utf8
        )

        let matched = await waitUntil {
            events.contains { if case .refsChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(matched, "应广播 .refsChanged，实际事件：\(events)")
    }

    func testUnchangedGitDirectoryDoesNotBroadcastDimensionEvents() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        // 写入一个不属于四个维度的文件（例如 `.git/config`）。
        try "config\n".write(
            to: repo.appendingPathComponent(".git/config"),
            atomically: true,
            encoding: .utf8
        )

        // 留出 debounce + FSEventStream 的时间窗，确认没有维度事件被广播。
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let dimensionEvents = events.filter {
            switch $0 {
            case .headChanged, .indexChanged, .stashChanged, .refsChanged: return true
            default: return false
            }
        }
        XCTAssertTrue(dimensionEvents.isEmpty, "不应广播维度事件：\(dimensionEvents)")
    }

    // MARK: - 工作区

    func testWorkingTreeChangeBroadcastsWorkingTreeChanged() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        try writeFileFromChildProcess(repo.appendingPathComponent("working-tree.txt"))

        let matched = await waitUntil {
            events.contains { if case .workingTreeChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(matched, "应广播 .workingTreeChanged，实际事件：\(events)")
    }

    func testWorkingTreeChangeIsThrottledWithinTwoSeconds() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        try writeFileFromChildProcess(repo.appendingPathComponent("first.txt"))

        let firstSeen = await waitUntil {
            events.contains { if case .workingTreeChanged = $0 { return true } else { return false } }
        }
        XCTAssertTrue(firstSeen, "首次工作区变化应广播事件，实际事件：\(events)")

        // 2 秒节流窗口内的第二次变化被丢弃。
        try writeFileFromChildProcess(repo.appendingPathComponent("second.txt"))
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let workingTreeCount = events.filter {
            if case .workingTreeChanged = $0 { return true } else { return false }
        }.count
        XCTAssertEqual(workingTreeCount, 1, "节流窗口内不应重复广播，实际事件：\(events)")

        // 超过节流窗口后再次变化应重新广播。
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        try writeFileFromChildProcess(repo.appendingPathComponent("third.txt"))
        let resuppressed = await waitUntil {
            events.filter { if case .workingTreeChanged = $0 { return true } else { return false } }.count >= 2
        }
        XCTAssertTrue(resuppressed, "超出节流窗口后应再次广播，实际事件：\(events)")
    }

    // MARK: - 切换仓库

    func testSwitchingRepositoryStopsPreviousWatcherAndBroadcastsStarted() async throws {
        let first = try makeSyntheticRepository()
        let second = try makeSyntheticRepository()
        defer {
            removeRepository(first)
            removeRepository(second)
        }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: first)
        XCTAssertEqual(provider.watchingRepositoryURL, first.standardizedFileURL)

        provider.startWatching(repositoryURL: second)

        XCTAssertEqual(provider.watchingRepositoryURL, second.standardizedFileURL)
        XCTAssertTrue(provider.isWatcherActive)
        let started = events.filter { if case .started = $0 { return true } else { return false } }
        XCTAssertEqual(started.count, 2, "切换仓库应各自广播一次 .started，实际事件：\(events)")
        // 切换仓库不广播 .stopped（内部 teardown 显式关闭了事件）。
        let stopped = events.filter { if case .stopped = $0 { return true } else { return false } }
        XCTAssertTrue(stopped.isEmpty, "切换仓库不应广播 .stopped，实际事件：\(events)")
    }

    func testStartingSameRepositoryTwiceIsIdempotent() async throws {
        let repo = try makeSyntheticRepository()
        defer { removeRepository(repo) }
        let provider = GitRepositoryWatchProvider()
        var events: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repo)
        provider.startWatching(repositoryURL: repo)

        let started = events.filter { if case .started = $0 { return true } else { return false } }
        XCTAssertEqual(started.count, 1, "重复监听同一仓库应保持幂等，实际事件：\(events)")
    }
}
