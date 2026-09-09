import Foundation
import KitGit
import Testing
@testable import PluginActivityHeatmap

@MainActor
@Suite("LocalActivityHeatmapProvider")
struct LocalActivityHeatmapProviderTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("aggregates commits by calendar day")
    func aggregatesCommitsByCalendarDay() {
        let calendar = calendar
        let repository = URL(fileURLWithPath: "/tmp/activity-repo")
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 8))!
        let commits = [
            GitCommit(hash: "1", shortHash: "1", message: "one", author: "A", date: day.addingTimeInterval(60)),
            GitCommit(hash: "2", shortHash: "2", message: "two", author: "A", date: day.addingTimeInterval(120)),
            GitCommit(hash: "3", shortHash: "3", message: "three", author: "B", date: day.addingTimeInterval(-86_400)),
        ]

        let snapshot = LocalActivityHeatmapProvider.makeSnapshot(
            repository: repository,
            commits: commits,
            calendar: calendar,
            now: day,
            generatedAt: day
        )

        #expect(snapshot.days.map(\.commitCount) == [1, 2])
        #expect(snapshot.totalCommitCount == 3)
    }

    @Test("publishes cached data before the refresh completes")
    func publishesCachedDataBeforeRefreshCompletes() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let calendar = calendar
        let repository = URL(fileURLWithPath: "/tmp/cached-repo")
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 8))!
        let cached = LocalActivityHeatmapProvider.makeSnapshot(
            repository: repository,
            commits: [],
            calendar: calendar,
            now: now,
            generatedAt: now
        )

        let first = LocalActivityHeatmapProvider(
            directory: directory,
            calendar: calendar,
            now: { now },
            commitLoader: { _, _, _ in [] },
            statusLoader: { _ in GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main") }
        )
        first.refresh(for: repository)
        try await waitUntil { first.currentSnapshot != nil }

        let second = LocalActivityHeatmapProvider(
            directory: directory,
            calendar: calendar,
            now: { now },
            commitLoader: { _, _, _ in [] },
            statusLoader: { _ in GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main") }
        )
        second.refresh(for: repository)

        #expect(second.currentSnapshot == cached)
        #expect(!second.isLoading)
    }

    @Test("clears loading after a refresh completes")
    func clearsLoadingAfterRefreshCompletes() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = URL(fileURLWithPath: "/tmp/loading-repo")
        let provider = LocalActivityHeatmapProvider(
            directory: directory,
            commitLoader: { _, _, _ in [] },
            statusLoader: { _ in GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main") }
        )

        provider.refresh(for: repository)

        #expect(provider.isLoading)
        for _ in 0..<100 {
            if !provider.isLoading { break }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(!provider.isLoading)
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool
    ) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        Issue.record("Timed out waiting for refresh")
    }
}
