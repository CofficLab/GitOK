import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目卷状态模型的单元测试：缓存、刷新时机与侧边栏标识。
@MainActor
final class ProjectVolumeModelTests: XCTestCase {
    /// 测试替身：按项目路径返回预设的卷类型，并记录调用次数。
    private final class StubResolver: ProjectVolumeResolving, @unchecked Sendable {
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
            lock.withLock { _callCount += 1 }
            return lock.withLock { _statuses[url.path] } ?? .unavailable
        }
    }

    func testRefreshLoadsVolumeStatusesForAllProjects() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/External"] = .externalVolume
        resolver.statuses["/tmp/Missing"] = .unavailable

        let model = ProjectVolumeModel(resolver: resolver)
        let external = Project(url: URL(fileURLWithPath: "/tmp/External"))
        let missing = Project(url: URL(fileURLWithPath: "/tmp/Missing"))

        model.refresh(for: [external, missing])
        await waitUntil { model.statuses.count == 2 }

        XCTAssertEqual(model.statuses[external.id], .externalVolume)
        XCTAssertEqual(model.statuses[missing.id], .unavailable)
        XCTAssertEqual(model.badge(for: external.id), .external)
        XCTAssertEqual(model.badge(for: missing.id), .unavailable)
    }

    func testRefreshSkipsAlreadyCachedProjects() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/External"] = .externalVolume

        let model = ProjectVolumeModel(resolver: resolver)
        let project = Project(url: URL(fileURLWithPath: "/tmp/External"))

        model.refresh(for: [project])
        await waitUntil { model.statuses[project.id] != nil }
        XCTAssertEqual(resolver.callCount, 1)

        // 再次刷新：命中缓存，不应重复查询文件系统。
        model.refresh(for: [project])
        await Task.yield()
        XCTAssertEqual(resolver.callCount, 1, "已缓存的卷状态不应重复读取")
    }

    func testForceRefreshReevaluatesCachedProjects() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/External"] = .externalVolume

        let model = ProjectVolumeModel(resolver: resolver)
        let project = Project(url: URL(fileURLWithPath: "/tmp/External"))

        model.refresh(for: [project])
        await waitUntil { model.statuses[project.id] != nil }
        XCTAssertEqual(resolver.callCount, 1)

        // 应用回前台 / 卷挂载变化时强制重新判定。
        model.refresh(for: [project], force: true)
        await waitUntil { resolver.callCount == 2 }
        XCTAssertEqual(resolver.callCount, 2)
    }

    func testRefreshRemovesCacheForDeletedProjects() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/External"] = .externalVolume

        let model = ProjectVolumeModel(resolver: resolver)
        let project = Project(url: URL(fileURLWithPath: "/tmp/External"))

        model.refresh(for: [project])
        await waitUntil { model.statuses.count == 1 }

        model.refresh(for: [])
        XCTAssertTrue(model.statuses.isEmpty, "项目被移除后应清理卷状态缓存")
    }

    func testURLChangeInvalidatesCache() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/Internal"] = .internalVolume
        resolver.statuses["/tmp/External"] = .externalVolume

        let projectID = UUID()
        let model = ProjectVolumeModel(resolver: resolver)
        let internalProject = Project(id: projectID, url: URL(fileURLWithPath: "/tmp/Internal"))

        model.refresh(for: [internalProject])
        await waitUntil { model.statuses[projectID] == .internalVolume }

        // 同一项目换了路径：即使不强制刷新也应重新判定。
        let externalProject = Project(id: projectID, url: URL(fileURLWithPath: "/tmp/External"))
        model.refresh(for: [externalProject])
        await waitUntil { model.statuses[projectID] == .externalVolume }

        XCTAssertEqual(resolver.callCount, 2, "项目路径变化后应重新读取卷属性")
        XCTAssertEqual(model.badge(for: projectID), .external)
    }

    func testBadgeMappingForInternalVolumeIsNone() async {
        let resolver = StubResolver()
        resolver.statuses["/tmp/Internal"] = .internalVolume

        let model = ProjectVolumeModel(resolver: resolver)
        let project = Project(url: URL(fileURLWithPath: "/tmp/Internal"))

        model.refresh(for: [project])
        await waitUntil { model.statuses[project.id] != nil }

        XCTAssertEqual(model.badge(for: project.id), .none, "本机卷不应显示徽标")
    }

    func testBadgeIsNoneBeforeStatusIsResolved() {
        let model = ProjectVolumeModel(resolver: StubResolver())
        let project = Project(url: URL(fileURLWithPath: "/tmp/External"))

        XCTAssertEqual(model.badge(for: project.id), .none, "尚未判定完成时不显示徽标")
    }

    // MARK: - Helpers

    private func waitUntil(
        timeout: TimeInterval = 1,
        _ condition: @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTFail("等待条件超时", file: file, line: line)
    }
}
