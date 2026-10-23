import Foundation
import Testing
@testable import ProviderActivityHeatmap

/// 覆盖 `DefaultActivityHeatmapProvider` 观察者体系与快照归一化中
/// 既有用例没有触达的分支。
@MainActor
@Suite("ProviderActivityHeatmap 边界行为")
struct ActivityHeatmapProvidingEdgeTests {

    // MARK: - 快照归一化

    @Test("负数提交数被归零")
    func negativeCommitCountIsClamped() {
        let day = ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: -9)

        #expect(day.commitCount == 0)
    }

    @Test("空快照的总提交数为零")
    func emptySnapshotHasZeroTotal() {
        let snapshot = ActivityHeatmapSnapshot(repositoryPath: "/tmp/repo", days: [])

        #expect(snapshot.totalCommitCount == 0)
        #expect(snapshot.days.isEmpty)
    }

    @Test("快照按日期升序排列")
    func snapshotSortsDaysByDate() {
        let first = Date(timeIntervalSince1970: 100)
        let second = Date(timeIntervalSince1970: 200)
        let third = Date(timeIntervalSince1970: 300)

        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [
                ActivityHeatmapDay(date: third, commitCount: 1),
                ActivityHeatmapDay(date: first, commitCount: 2),
                ActivityHeatmapDay(date: second, commitCount: 3),
            ]
        )

        #expect(snapshot.days.map(\.date) == [first, second, third])
        #expect(snapshot.totalCommitCount == 6)
    }

    // MARK: - Provider 状态广播

    @Test("初始快照不触发事件")
    func initialSnapshotDoesNotNotify() {
        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 1)]
        )
        let provider = DefaultActivityHeatmapProvider(snapshot: snapshot)
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        #expect(provider.currentSnapshot == snapshot)
        #expect(count == 0)
    }

    @Test("相同快照不重复广播")
    func identicalSnapshotDoesNotNotify() {
        let provider = DefaultActivityHeatmapProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 1)]
        )

        provider.setSnapshot(snapshot)
        provider.setSnapshot(snapshot)

        #expect(count == 1)
    }

    @Test("清空快照会广播快照变化")
    func clearingSnapshotNotifies() {
        let provider = DefaultActivityHeatmapProvider()
        var events: [ActivityHeatmapEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 1)]
        )

        provider.setSnapshot(snapshot)
        provider.setSnapshot(nil)

        #expect(events.count == 2)
        #expect(events.allSatisfy { $0 == .snapshotChanged })
        #expect(provider.currentSnapshot == nil)
    }

    @Test("加载状态与快照状态分别广播对应事件")
    func emitsMatchingEventKinds() {
        let provider = DefaultActivityHeatmapProvider()
        var events: [ActivityHeatmapEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setLoading(true)
        provider.setSnapshot(
            ActivityHeatmapSnapshot(
                repositoryPath: "/tmp/repo",
                days: [ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 1)]
            )
        )
        provider.setLoading(false)

        #expect(events == [.loadingChanged, .snapshotChanged, .loadingChanged])
    }

    @Test("取消订阅后不再收到事件")
    func cancelledObserverStopsReceivingEvents() {
        let provider = DefaultActivityHeatmapProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        provider.setLoading(true)
        #expect(count == 1)

        handle.cancel()
        provider.setLoading(false)
        provider.setSnapshot(nil)

        #expect(count == 1)
    }

    @Test("重复取消订阅是幂等的")
    func cancelIsIdempotent() {
        let provider = DefaultActivityHeatmapProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        handle.cancel()
        handle.cancel()

        provider.setLoading(true)

        #expect(count == 0)
    }

    @Test("多个观察者都会收到广播")
    func broadcastsToAllObservers() {
        let provider = DefaultActivityHeatmapProvider()
        var first = 0
        var second = 0
        let firstHandle = provider.addObserver { _ in first += 1 }
        let secondHandle = provider.addObserver { _ in second += 1 }
        defer {
            firstHandle.cancel()
            secondHandle.cancel()
        }

        provider.setLoading(true)

        #expect(first == 1)
        #expect(second == 1)
    }
}
