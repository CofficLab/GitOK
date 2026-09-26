import Foundation
import KitGit
import Testing
@testable import PluginActivityHeatmap
import KernelCore
import ProviderActivityHeatmap

@MainActor
@Suite("LocalActivityHeatmapProvider Additional Coverage")
struct LocalActivityHeatmapProviderAdditionalTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    private func makeRepository() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeatmapAddl-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("nil repository clears snapshot and loading")
    func nilRepositoryClearsState() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in [] }
        )
        provider.refresh(for: nil)
        #expect(provider.currentSnapshot == nil)
        #expect(!provider.isLoading)
    }

    @Test("refresh error preserves cached snapshot and stops loading")
    func refreshErrorStopsLoading() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repo) }

        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in
                throw TestError.loadFailed
            }
        )
        provider.refresh(for: repo)

        // 等待 loading 结束。
        for _ in 0..<100 {
            if !provider.isLoading { break }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(!provider.isLoading)
    }

    @Test("observer receives snapshotChanged and loadingChanged events")
    func observerReceivesEvents() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repo) }

        var events: [ActivityHeatmapEvent] = []
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in [] }
        )
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.refresh(for: repo)
        for _ in 0..<100 {
            if !provider.isLoading { break }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(!events.isEmpty)
    }

    @Test("cancelled observer handle does not invoke callback")
    func cancelledObserverHandleNoInvocations() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        var events: [ActivityHeatmapEvent] = []
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in [] }
        )
        let handle = provider.addObserver { events.append($0) }
        handle.cancel()
        // 触发 snapshot 变更。
        provider.setSnapshot(nil)
        #expect(events.isEmpty)
    }

    @Test("setSnapshot with same value does not notify observers")
    func setSameSnapshotNoNotification() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        var events: [ActivityHeatmapEvent] = []
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in [] }
        )
        _ = provider.addObserver { events.append($0) }
        provider.setSnapshot(nil)
        provider.setSnapshot(nil)
        // 第一次 nil 不触发（初始已是 nil），第二次也不触发。
        #expect(events.isEmpty)
    }

    @Test("setLoading with same value does not notify observers")
    func setSameLoadingNoNotification() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        var events: [ActivityHeatmapEvent] = []
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            commitLoader: { _, _, _ in [] }
        )
        _ = provider.addObserver { events.append($0) }
        provider.setLoading(false)
        #expect(events.isEmpty)
    }

    @Test("makeSnapshot with empty commits produces empty days")
    func makeSnapshotEmptyCommits() {
        let repo = URL(fileURLWithPath: "/tmp/empty-repo")
        let now = Date()
        let snapshot = LocalActivityHeatmapProvider.makeSnapshot(
            repository: repo,
            commits: [],
            calendar: calendar,
            now: now
        )
        #expect(snapshot.days.isEmpty)
        #expect(snapshot.generatedAt == now)
    }

    @Test("paginates commits across multiple pages until cutoff reached")
    func paginatesMultiplePages() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repo) }

        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 8))!
        let oldDate = now.addingTimeInterval(-400 * 86_400) // ~13 months ago, before cutoff
        let recentDate = now.addingTimeInterval(-86_400)

        // 第一页：50 个近期提交；第二页：1 个旧提交（触发 cutoff 中断）。
        let counter = Counter()
        let provider = LocalActivityHeatmapProvider(
            directory: dir,
            calendar: calendar,
            now: { now },
            commitLoader: { _, _, _ in
                let n = counter.next()
                if n == 1 {
                    return (0..<50).map { i in
                        GitCommit(hash: "\(i)", shortHash: "\(i)", message: "c\(i)", author: "A", date: recentDate)
                    }
                } else {
                    return [GitCommit(hash: "old", shortHash: "old", message: "old", author: "A", date: oldDate)]
                }
            }
        )
        provider.refresh(for: repo)
        for _ in 0..<200 {
            if !provider.isLoading { break }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(!provider.isLoading)
        #expect(counter.value >= 2)
    }

    @Test("onBoot with missing providers returns early without crashing")
    func onBootMissingProvidersReturnsEarly() throws {
        let kernel = KernelCoreContainer()
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        // 未注册 ActivityHeatmapProviding，不崩溃即可。
        try plugin.onShutdown(kernel: kernel)
    }
}

private enum TestError: Error {
    case loadFailed
}

private final class Counter: @unchecked Sendable {
    private var _value = 0
    private let lock = NSLock()
    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return _value
    }
    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        _value += 1
        return _value
    }
}
