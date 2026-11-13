import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 回归：根布局在工作区状态变化（切换项目、卷不可用等）时会重建侧边栏视图。
///
/// 提交时间与卷状态缓存曾由视图的 `@StateObject` 持有，重建后缓存被清空：
/// 「最近更新」列表先退化成字母序，卷徽标也重新闪一遍。缓存上提到 Provider
/// 之后，重建只重新绑定视图，不应丢失缓存或重新读取。
@MainActor
final class ProjectSidebarCacheTests: XCTestCase {
    func testActivityCacheSurvivesSidebarViewRebuilds() async {
        let capability = StubActivityCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)
        let projects = StubSidebarProjects(
            projects: [Project(url: URL(fileURLWithPath: "/tmp/A"))]
        )
        let provider = ProjectSidebarProviding(
            projects: projects,
            activityCapability: capability
        )

        provider.activityModel.refresh(for: projects.projects)
        await waitUntil { provider.activityModel.commitDates.count == 1 }

        // 根布局重建侧边栏视图。
        _ = provider.makeSidebarView()
        _ = provider.makeSidebarView()

        XCTAssertEqual(
            provider.activityModel.commitDates.count,
            1,
            "重建后提交时间缓存不应丢失"
        )

        provider.activityModel.refresh(for: projects.projects)
        await Task.yield()

        XCTAssertEqual(capability.callCount, 1, "重建后不应重新读取已缓存的项目")
    }

    func testVolumeCacheSurvivesSidebarViewRebuilds() async {
        let resolver = StubVolumeResolver()
        resolver.statuses["/tmp/External"] = .externalVolume
        let projects = StubSidebarProjects(
            projects: [Project(url: URL(fileURLWithPath: "/tmp/External"))]
        )
        let provider = ProjectSidebarProviding(
            projects: projects,
            volumeResolver: resolver
        )

        provider.volumeModel.refresh(for: projects.projects)
        await waitUntil { provider.volumeModel.statuses.count == 1 }

        // 根布局重建侧边栏视图。
        _ = provider.makeSidebarView()
        _ = provider.makeSidebarView()

        XCTAssertEqual(
            provider.volumeModel.badge(for: projects.projects[0].id),
            .external,
            "重建后卷状态缓存不应丢失"
        )

        provider.volumeModel.refresh(for: projects.projects)
        await Task.yield()

        XCTAssertEqual(resolver.callCount, 1, "重建后不应重新判定已缓存的卷")
    }

    // MARK: - Helpers

    private func waitUntil(
        _ condition: @escaping () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<200 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTFail("等待条件超时", file: file, line: line)
    }
}

// MARK: - Test Doubles

private final class StubActivityCapability: ProjectActivityCapability, @unchecked Sendable {
    private let lock = NSLock()
    private var _dates: [String: Date] = [:]
    private var _callCount = 0

    var dates: [String: Date] {
        get { lock.withLock { _dates } }
        set { lock.withLock { _dates = newValue } }
    }

    var callCount: Int {
        lock.withLock { _callCount }
    }

    func lastCommitDate(inRepository repositoryURL: URL) async -> Date? {
        lock.withLock {
            _callCount += 1
            return _dates[repositoryURL.path]
        }
    }
}

private final class StubVolumeResolver: ProjectVolumeResolving, @unchecked Sendable {
    private let lock = NSLock()
    private var _statuses: [String: ProjectVolumeStatus] = [:]
    private var _callCount = 0

    var statuses: [String: ProjectVolumeStatus] {
        get { lock.withLock { _statuses } }
        set { lock.withLock { _statuses = newValue } }
    }

    var callCount: Int {
        lock.withLock { _callCount }
    }

    func status(forProjectURL url: URL) async -> ProjectVolumeStatus {
        lock.withLock {
            _callCount += 1
            return _statuses[url.path] ?? .unavailable
        }
    }
}

@MainActor
private final class StubSidebarProjects: ProjectSidebarCapability {
    let projects: [Project]
    var currentProject: Project? { nil }

    init(projects: [Project]) {
        self.projects = projects
    }

    func addProject(at url: URL) {}
    func openProject(at url: URL) {}
    func setCurrentProject(id: UUID?) {}
    func removeProject(id: UUID) {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func renameProject(id: UUID, newName: String) throws {}
    func notifyDataChanged() {}

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        StubObserverHandle()
    }
}

private final class StubObserverHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
