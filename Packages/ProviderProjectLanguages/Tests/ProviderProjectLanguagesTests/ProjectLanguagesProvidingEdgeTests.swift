import Foundation
import Testing
@testable import ProviderProjectLanguages

/// 覆盖 `ProjectLanguagesSnapshot` 归一化规则与 `DefaultProjectLanguagesProvider`
/// 观察者体系中既有用例没有触达的分支。
@MainActor
@Suite("ProviderProjectLanguages 边界行为")
struct ProjectLanguagesProvidingEdgeTests {

    // MARK: - Snapshot 归一化

    @Test("负数字节数被归零")
    func negativeByteCountIsClamped() {
        let language = ProjectLanguage(id: "swift", name: "Swift", byteCount: -12)

        #expect(language.byteCount == 0)
    }

    @Test("零字节语言被过滤出快照")
    func zeroByteLanguagesAreFilteredOut() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [
                ProjectLanguage(id: "swift", name: "Swift", byteCount: 10),
                ProjectLanguage(id: "empty", name: "Empty", byteCount: 0),
            ]
        )

        #expect(snapshot.languages.map(\.id) == ["swift"])
        #expect(snapshot.totalByteCount == 10)
    }

    @Test("字节数相同时按语言名升序排列")
    func equalByteCountsSortByName() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [
                ProjectLanguage(id: "z", name: "Zig", byteCount: 5),
                ProjectLanguage(id: "c", name: "C", byteCount: 5),
                ProjectLanguage(id: "m", name: "Markdown", byteCount: 5),
            ]
        )

        #expect(snapshot.languages.map(\.name) == ["C", "Markdown", "Zig"])
    }

    @Test("总字节数为零时占比返回零")
    func percentageIsZeroWhenTotalIsZero() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: []
        )

        #expect(snapshot.totalByteCount == 0)
        #expect(snapshot.percentage(for: ProjectLanguage(id: "swift", name: "Swift", byteCount: 10)) == 0)
    }

    @Test("占比按总字节数计算")
    func percentageUsesTotalByteCount() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [
                ProjectLanguage(id: "swift", name: "Swift", byteCount: 30),
                ProjectLanguage(id: "md", name: "Markdown", byteCount: 10),
            ]
        )

        #expect(snapshot.percentage(for: snapshot.languages[0]) == 0.75)
        #expect(snapshot.percentage(for: snapshot.languages[1]) == 0.25)
    }

    // MARK: - Provider 状态广播

    @Test("初始快照不触发事件")
    func initialSnapshotDoesNotNotify() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )
        let provider = DefaultProjectLanguagesProvider(snapshot: snapshot)
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        #expect(provider.currentSnapshot == snapshot)
        #expect(count == 0)
    }

    @Test("相同快照不重复广播")
    func identicalSnapshotDoesNotNotify() {
        let provider = DefaultProjectLanguagesProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )

        provider.setSnapshot(snapshot)
        provider.setSnapshot(snapshot)

        #expect(count == 1)
    }

    @Test("清空快照会广播快照变化")
    func clearingSnapshotNotifies() {
        let provider = DefaultProjectLanguagesProvider()
        var events: [ProjectLanguagesEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )

        provider.setSnapshot(snapshot)
        provider.setSnapshot(nil)

        #expect(events.count == 2)
        #expect(provider.currentSnapshot == nil)
    }

    @Test("重复设置相同加载状态不广播")
    func identicalLoadingStateDoesNotNotify() {
        let provider = DefaultProjectLanguagesProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        provider.setLoading(true)
        provider.setLoading(true)
        provider.setLoading(false)
        provider.setLoading(false)

        #expect(count == 2)
        #expect(provider.isLoading == false)
    }

    @Test("取消订阅后不再收到事件")
    func cancelledObserverStopsReceivingEvents() {
        let provider = DefaultProjectLanguagesProvider()
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
        let provider = DefaultProjectLanguagesProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        handle.cancel()
        handle.cancel()

        provider.setLoading(true)

        #expect(count == 0)
    }

    @Test("refresh 不改变当前快照")
    func refreshKeepsSnapshot() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )
        let provider = DefaultProjectLanguagesProvider(snapshot: snapshot)

        provider.refresh(for: URL(fileURLWithPath: "/tmp/other"))

        #expect(provider.currentSnapshot == snapshot)
    }
}
