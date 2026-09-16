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
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
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
            commitLoader: { _, _, _ in [] }
        )
        first.refresh(for: repository)
        try await waitUntil { first.currentSnapshot != nil }

        let second = LocalActivityHeatmapProvider(
            directory: directory,
            calendar: calendar,
            now: { now },
            commitLoader: { _, _, _ in [] }
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

        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
        let provider = LocalActivityHeatmapProvider(
            directory: directory,
            commitLoader: { _, _, _ in [] }
        )

        provider.refresh(for: repository)

        #expect(provider.isLoading)
        for _ in 0..<100 {
            if !provider.isLoading { break }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(!provider.isLoading)
    }

    @Test("cancels a previous repository history scan when switching projects")
    func cancelsPreviousHistoryScan() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let firstRepository = try makeRepository()
        let secondRepository = try makeRepository()
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: firstRepository)
            try? FileManager.default.removeItem(at: secondRepository)
        }

        let probe = CancellationProbe()
        let provider = LocalActivityHeatmapProvider(
            directory: directory,
            cancellableCommitLoader: { repository, _, _, cancellation in
                if repository == firstRepository.standardizedFileURL {
                    probe.start(cancellation)
                    while cancellation?.isCancelled == false {
                        Thread.sleep(forTimeInterval: 0.005)
                    }
                    throw CancellationError()
                }
                return []
            }
        )

        provider.refresh(for: firstRepository)
        let didStart = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: probe.started.wait(timeout: .now() + 2) == .success)
            }
        }
        #expect(didStart)

        provider.refresh(for: secondRepository)

        #expect(probe.isCancelled)
        try await waitUntil { provider.currentSnapshot?.repositoryPath == secondRepository.path }
        #expect(!provider.isLoading)
    }

    @Test("does not start loading for a missing repository")
    func ignoresMissingRepository() {
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let missingRepository = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let provider = LocalActivityHeatmapProvider(
            directory: cacheDirectory,
            commitLoader: { _, _, _ in
                Issue.record("a missing repository must not start a Git query")
                return []
            }
        )

        provider.refresh(for: missingRepository)

        #expect(provider.currentSnapshot == nil)
        #expect(!provider.isLoading)
    }

    private func makeRepository() throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalActivityHeatmapProviderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        return repository
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

    private final class CancellationProbe: @unchecked Sendable {
        let started = DispatchSemaphore(value: 0)
        private let lock = NSLock()
        private var cancellation: GitProcessCancellation?

        var isCancelled: Bool {
            lock.lock()
            let cancellation = self.cancellation
            lock.unlock()
            return cancellation?.isCancelled == true
        }

        func start(_ cancellation: GitProcessCancellation?) {
            lock.lock()
            self.cancellation = cancellation
            lock.unlock()
            started.signal()
        }
    }
}
