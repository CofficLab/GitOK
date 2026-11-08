import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目活跃度模型的单元测试。
@MainActor
final class ProjectActivityModelTests: XCTestCase {
    /// 测试替身：按项目路径返回预设的提交时间，并记录调用次数。
    ///
    /// 能力协议要求 `Sendable`，因此这里用锁保护可变状态。
    private final class StubCapability: ProjectActivityCapability, @unchecked Sendable {
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
            lock.withLock { _callCount += 1 }
            return dates[repositoryURL.path]
        }
    }

    func testRefreshLoadsCommitDatesForAllProjects() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)
        capability.dates["/tmp/B"] = Date(timeIntervalSince1970: 200)

        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))
        let b = Project(url: URL(fileURLWithPath: "/tmp/B"))

        model.refresh(for: [a, b])
        await waitForCompletion(model)

        XCTAssertEqual(model.commitDates[a.id], Date(timeIntervalSince1970: 100))
        XCTAssertEqual(model.commitDates[b.id], Date(timeIntervalSince1970: 200))
        XCTAssertTrue(model.loadingProjectIDs.isEmpty, "读取完成后不应残留 loading 标记")
    }

    func testRefreshSkipsAlreadyCachedProjects() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)

        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCompletion(model)
        XCTAssertEqual(capability.callCount, 1)

        // 再次刷新：命中缓存，不应重复读取。
        model.refresh(for: [a])
        await waitForCompletion(model)
        XCTAssertEqual(capability.callCount, 1, "已缓存的项目不应重复读取")
    }

    func testRefreshRemovesCacheForDeletedProjects() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)

        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCompletion(model)
        XCTAssertEqual(model.commitDates.count, 1)

        // 项目被移除后，缓存应同步清理。
        model.refresh(for: [])
        XCTAssertTrue(model.commitDates.isEmpty, "项目被移除后应清理缓存")
    }

    func testMissingCapabilityDoesNotStartLoading() {
        let model = ProjectActivityModel(capability: nil)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])

        XCTAssertTrue(model.loadingProjectIDs.isEmpty)
        XCTAssertTrue(model.commitDates.isEmpty)
    }

    func testFailedLookupDoesNotCacheAndClearsLoading() async {
        let capability = StubCapability() // 无预设日期 → 读取失败

        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCompletion(model)

        XCTAssertTrue(model.commitDates.isEmpty, "读取失败不应写入缓存")
        XCTAssertTrue(model.loadingProjectIDs.isEmpty, "读取失败后应清除 loading 标记")
    }

    func testCancelClearsLoadingState() async {
        let capability = StubCapability()
        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        model.cancel()

        XCTAssertTrue(model.loadingProjectIDs.isEmpty, "取消后应清除 loading 标记")
    }

    // MARK: - Helpers

    /// 等待后台读取任务跑完。
    private func waitForCompletion(_ model: ProjectActivityModel) async {
        for _ in 0..<200 {
            if model.loadingProjectIDs.isEmpty {
                // 再让出一帧，确保最后一次写入已提交。
                await Task.yield()
                if model.loadingProjectIDs.isEmpty { return }
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
