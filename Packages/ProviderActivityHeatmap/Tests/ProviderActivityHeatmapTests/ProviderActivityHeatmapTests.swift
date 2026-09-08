import Foundation
import Testing
@testable import ProviderActivityHeatmap

@MainActor
@Suite("ProviderActivityHeatmap")
struct ProviderActivityHeatmapTests {
    @Test("publishes snapshots and notifies observers")
    func publishesSnapshotsAndNotifiesObservers() {
        let provider = DefaultActivityHeatmapProvider()
        var eventCount = 0
        let handle = provider.addObserver { _ in eventCount += 1 }
        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 2)]
        )

        provider.setSnapshot(snapshot)

        #expect(provider.currentSnapshot == snapshot)
        #expect(eventCount == 1)
        handle.cancel()
        provider.setSnapshot(nil)
        #expect(eventCount == 1)
    }

    @Test("normalizes activity data")
    func normalizesActivityData() {
        let later = ActivityHeatmapDay(date: Date(timeIntervalSince1970: 200), commitCount: -4)
        let earlier = ActivityHeatmapDay(date: Date(timeIntervalSince1970: 100), commitCount: 3)
        let snapshot = ActivityHeatmapSnapshot(
            repositoryPath: "/tmp/repo",
            days: [later, earlier]
        )

        #expect(snapshot.days.map(\.date) == [earlier.date, later.date])
        #expect(snapshot.days[1].commitCount == 0)
        #expect(snapshot.totalCommitCount == 3)
    }

    @Test("publishes loading state changes")
    func publishesLoadingStateChanges() {
        let provider = DefaultActivityHeatmapProvider()
        var events: [ActivityHeatmapEvent] = []
        let handle = provider.addObserver { events.append($0) }

        provider.setLoading(true)
        provider.setLoading(true)
        provider.setLoading(false)

        #expect(provider.isLoading == false)
        #expect(events.count == 2)
        handle.cancel()
    }
}
