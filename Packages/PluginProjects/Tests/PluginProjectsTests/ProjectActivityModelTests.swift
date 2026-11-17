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

    // MARK: - Force refresh

    /// 强制刷新忽略缓存重读：外部提交后回到前台时排序键才会更新。
    func testForceRefreshRereadsCachedProjects() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)

        let model = ProjectActivityModel(capability: capability, minimumForceInterval: 0)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCompletion(model)
        XCTAssertEqual(model.commitDates[a.id], Date(timeIntervalSince1970: 100))

        // 在其他软件里提交后，缓存里的旧时间必须被覆盖。
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 300)
        model.refresh(for: [a], force: true)
        await waitForCompletion(model)

        XCTAssertEqual(capability.callCount, 2, "强制刷新应重读已缓存的项目")
        XCTAssertEqual(model.commitDates[a.id], Date(timeIntervalSince1970: 300))
    }

    /// 冷却期内重复的强制刷新会被忽略，避免频繁切换窗口时反复全量读取。
    func testForceRefreshWithinCooldownIsIgnored() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)

        let model = ProjectActivityModel(capability: capability, minimumForceInterval: 60)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCompletion(model)
        XCTAssertEqual(capability.callCount, 1)

        model.refresh(for: [a], force: true)
        await waitForCompletion(model)
        XCTAssertEqual(capability.callCount, 2)

        // 仍在冷却窗口内：不应再发起读取。
        model.refresh(for: [a], force: true)
        await waitForCompletion(model)
        XCTAssertEqual(capability.callCount, 2, "冷却期内的强制刷新应被忽略")
    }

    /// 非强制刷新不受冷却影响：新增项目仍要补读。
    func testNonForceRefreshIsNotThrottled() async {
        let capability = StubCapability()
        capability.dates["/tmp/A"] = Date(timeIntervalSince1970: 100)
        capability.dates["/tmp/B"] = Date(timeIntervalSince1970: 200)

        let model = ProjectActivityModel(capability: capability, minimumForceInterval: 60)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))
        let b = Project(url: URL(fileURLWithPath: "/tmp/B"))

        model.refresh(for: [a])
        await waitForCompletion(model)

        model.refresh(for: [a, b])
        await waitForCompletion(model)

        XCTAssertEqual(model.commitDates[b.id], Date(timeIntervalSince1970: 200), "新增项目应补读")
    }

    // MARK: - Atomic publish

    /// 整轮读取结束后一次性生效：读取期间列表顺序不应随进度反复变化。
    func testResultsPublishOnlyOnceAtEndOfPass() async {
        let capability = GatedStubCapability()
        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))
        let b = Project(url: URL(fileURLWithPath: "/tmp/B"))

        model.refresh(for: [a, b])
        await waitForCalls(capability, count: 2)

        XCTAssertTrue(model.commitDates.isEmpty, "读取进行中不应写入提交时间")
        XCTAssertEqual(model.loadingProjectIDs.count, 2)

        capability.resumeAll()
        await waitForCompletion(model)

        XCTAssertEqual(model.commitDates.count, 2, "读取完成后结果一次性生效")
    }

    /// 读取中途被取消时，过期结果不得写入缓存。
    func testCancelledPassDoesNotPublishResults() async {
        let capability = GatedStubCapability()
        let model = ProjectActivityModel(capability: capability)
        let a = Project(url: URL(fileURLWithPath: "/tmp/A"))

        model.refresh(for: [a])
        await waitForCalls(capability, count: 1)

        model.cancel()
        capability.resumeAll()
        try? await Task.sleep(nanoseconds: 50_000_000)
        await Task.yield()

        XCTAssertTrue(model.commitDates.isEmpty, "已取消的轮次不应写入结果")
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

    /// 等待能力层收到预期数量的读取请求。
    private func waitForCalls(
        _ capability: GatedStubCapability,
        count: Int
    ) async {
        for _ in 0..<200 {
            if capability.callCount >= count { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertEqual(capability.callCount, count, "读取请求数未达到预期")
    }

    /// 测试替身：挂起读取请求，直到测试显式放行。
    ///
    /// 用于构造「读取进行中」的稳定时序，避免依赖 sleep 造成偶发失败。
    private final class GatedStubCapability: ProjectActivityCapability, @unchecked Sendable {
        private let lock = NSLock()
        private var pending: [CheckedContinuation<Date?, Never>] = []
        private var _callCount = 0

        /// 放行时统一返回的提交时间。
        var date = Date(timeIntervalSince1970: 500)

        var callCount: Int { lock.withLock { _callCount } }

        func lastCommitDate(inRepository repositoryURL: URL) async -> Date? {
            await withCheckedContinuation { continuation in
                lock.withLock {
                    _callCount += 1
                    pending.append(continuation)
                }
            }
        }

        /// 放行全部挂起的读取请求。
        func resumeAll() {
            let waiting = lock.withLock {
                let copy = pending
                pending.removeAll()
                return copy
            }
            for continuation in waiting {
                continuation.resume(returning: date)
            }
        }
    }
}
