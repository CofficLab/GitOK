import Foundation
import XCTest
@testable import ProviderGitRepositoryWatch

@MainActor
final class ProviderGitRepositoryWatchTests: XCTestCase {

    // MARK: - Initial state

    func testInitialStateNotWatching() {
        let watching = DefaultGitRepositoryWatching()
        XCTAssertNil(watching.watchingRepositoryURL)
    }

    // MARK: - startWatching

    func testStartWatchingBroadcastsStarted() {
        let watching = DefaultGitRepositoryWatching()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = watching.addObserver { received.append($0) }
        defer { handle.cancel() }

        let url = URL(fileURLWithPath: "/tmp/MyRepo")
        watching.startWatching(repositoryURL: url)

        XCTAssertEqual(watching.watchingRepositoryURL, url.standardizedFileURL)
        XCTAssertEqual(received.count, 1)
        if case .started(let u) = received.first {
            XCTAssertEqual(u, url.standardizedFileURL)
        } else {
            XCTFail("expected .started, got \(received.first.debugDescription)")
        }
    }

    func testStartWatchingSameURLIsIdempotent() {
        let watching = DefaultGitRepositoryWatching()
        var count = 0
        let handle = watching.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        let url = URL(fileURLWithPath: "/tmp/MyRepo")
        watching.startWatching(repositoryURL: url)
        watching.startWatching(repositoryURL: url)

        XCTAssertEqual(count, 1)
    }

    func testStartWatchingDifferentURLReplaces() {
        let watching = DefaultGitRepositoryWatching()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = watching.addObserver { received.append($0) }
        defer { handle.cancel() }

        watching.startWatching(repositoryURL: URL(fileURLWithPath: "/tmp/RepoA"))
        watching.startWatching(repositoryURL: URL(fileURLWithPath: "/tmp/RepoB"))

        XCTAssertEqual(watching.watchingRepositoryURL, URL(fileURLWithPath: "/tmp/RepoB").standardizedFileURL)
        // 两次 .started，中间没有 .stopped（默认实现不主动发 stop，
        // 真正实现方可按需加；这里只校验状态最终一致 + 事件序列完整）。
        XCTAssertEqual(received.count, 2)
    }

    // MARK: - stopWatching

    func testStopWatchingBroadcastsStopped() {
        let watching = DefaultGitRepositoryWatching()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = watching.addObserver { received.append($0) }
        defer { handle.cancel() }

        watching.startWatching(repositoryURL: URL(fileURLWithPath: "/tmp/MyRepo"))
        watching.stopWatching()

        XCTAssertNil(watching.watchingRepositoryURL)
        XCTAssertEqual(received.count, 2)
        if case .stopped = received.last {
            // ok
        } else {
            XCTFail("expected .stopped as last event")
        }
    }

    func testStopWatchingWhenNotWatchingIsNoop() {
        let watching = DefaultGitRepositoryWatching()
        var count = 0
        let handle = watching.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        watching.stopWatching()
        XCTAssertEqual(count, 0)
        XCTAssertNil(watching.watchingRepositoryURL)
    }

    // MARK: - Observer handle

    func testCancelHandleStopsCallbacks() {
        let watching = DefaultGitRepositoryWatching()
        var count = 0
        let handle = watching.addObserver { _ in count += 1 }
        handle.cancel()

        watching.startWatching(repositoryURL: URL(fileURLWithPath: "/tmp/MyRepo"))
        XCTAssertEqual(count, 0)
    }

    func testCancelHandleIsIdempotent() {
        let watching = DefaultGitRepositoryWatching()
        let handle = watching.addObserver { _ in }
        handle.cancel()
        handle.cancel() // 不应崩溃
    }

    // MARK: - broadcast

    func testBroadcastReachesAllObservers() {
        let watching = DefaultGitRepositoryWatching()
        var countA = 0
        var countB = 0
        let handleA = watching.addObserver { _ in countA += 1 }
        let handleB = watching.addObserver { _ in countB += 1 }
        defer {
            handleA.cancel()
            handleB.cancel()
        }

        watching.broadcast(.indexChanged)
        XCTAssertEqual(countA, 1)
        XCTAssertEqual(countB, 1)

        watching.broadcast(.stashChanged)
        XCTAssertEqual(countA, 2)
        XCTAssertEqual(countB, 2)
    }

    func testBroadcastWithCancellationOnlyHitsRemainingObservers() {
        let watching = DefaultGitRepositoryWatching()
        var countA = 0
        var countB = 0
        let handleA = watching.addObserver { _ in countA += 1 }
        let handleB = watching.addObserver { _ in countB += 1 }

        handleA.cancel()
        watching.broadcast(.refsChanged)

        XCTAssertEqual(countA, 0)
        XCTAssertEqual(countB, 1)

        handleB.cancel()
    }

    // MARK: - Event equatable

    func testEventEquatable() {
        XCTAssertEqual(
            GitRepositoryWatchingEvent.indexChanged,
            GitRepositoryWatchingEvent.indexChanged
        )
        XCTAssertNotEqual(
            GitRepositoryWatchingEvent.indexChanged,
            GitRepositoryWatchingEvent.stashChanged
        )
        XCTAssertEqual(
            GitRepositoryWatchingEvent.headChanged(previousHead: "a", head: "b"),
            GitRepositoryWatchingEvent.headChanged(previousHead: "a", head: "b")
        )
        XCTAssertNotEqual(
            GitRepositoryWatchingEvent.headChanged(previousHead: "a", head: "b"),
            GitRepositoryWatchingEvent.headChanged(previousHead: "a", head: "c")
        )
    }
}
