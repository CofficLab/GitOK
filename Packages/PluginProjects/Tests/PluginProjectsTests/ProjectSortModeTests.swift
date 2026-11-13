import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目展示方式（排序规则）的单元测试。
@MainActor
final class ProjectSortModeTests: XCTestCase {
    // MARK: - Manual

    func testManualModeKeepsOriginalOrder() {
        let projects = [
            project("Zeta", isPinned: false),
            project("Alpha", isPinned: false),
            project("Mid", isPinned: false),
        ]

        let sorted = ProjectSortMode.manual.sorted(projects)

        XCTAssertEqual(sorted.map(\.title), ["Zeta", "Alpha", "Mid"])
    }

    // MARK: - Name

    func testNameModeSortsCaseInsensitivelyByTitle() {
        let projects = [
            project("zebra"),
            project("Apple"),
            project("mango"),
        ]

        let sorted = ProjectSortMode.name.sorted(projects)

        XCTAssertEqual(sorted.map(\.title), ["Apple", "mango", "zebra"])
    }

    func testNameModeKeepsPinnedProjectsFirst() {
        let projects = [
            project("Zeta"),
            project("Alpha", isPinned: true),
            project("Mid"),
        ]

        let sorted = ProjectSortMode.name.sorted(projects)

        XCTAssertEqual(sorted.map(\.title), ["Alpha", "Mid", "Zeta"], "置顶项目始终在最前")
    }

    func testNameModeBreaksTieByPath() {
        let first = project("Same", path: "/tmp/a")
        let second = project("Same", path: "/tmp/b")

        let sorted = ProjectSortMode.name.sorted([second, first])

        XCTAssertEqual(sorted.map(\.url.path), ["/tmp/a", "/tmp/b"])
    }

    // MARK: - Recent

    func testRecentModeSortsByCommitDateDescending() {
        let oldest = project("Oldest")
        let newest = project("Newest")
        let middle = project("Middle")
        let dates: [UUID: Date] = [
            oldest.id: Date(timeIntervalSince1970: 100),
            newest.id: Date(timeIntervalSince1970: 300),
            middle.id: Date(timeIntervalSince1970: 200),
        ]

        let sorted = ProjectSortMode.recent.sorted([oldest, newest, middle], commitDates: dates)

        XCTAssertEqual(sorted.map(\.title), ["Newest", "Middle", "Oldest"])
    }

    func testRecentModeRanksProjectsWithoutCommitDateLast() {
        let dated = project("Dated", lastOpenedAt: Date(timeIntervalSince1970: 1))
        let missing = project("Missing", lastOpenedAt: Date(timeIntervalSince1970: 9_999))

        let sorted = ProjectSortMode.recent.sorted(
            [missing, dated],
            commitDates: [dated.id: Date(timeIntervalSince1970: 100)]
        )

        XCTAssertEqual(
            sorted.map(\.title),
            ["Dated", "Missing"],
            "没有提交时间的项目排在最后，即使刚刚打开过"
        )
    }

    func testOpeningAProjectDoesNotChangeRecentOrder() {
        let alpha = project("Alpha", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let beta = project("Beta", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let gamma = project("Gamma", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let dates: [UUID: Date] = [
            alpha.id: Date(timeIntervalSince1970: 300),
            beta.id: Date(timeIntervalSince1970: 200),
            gamma.id: Date(timeIntervalSince1970: 100),
        ]

        let before = ProjectSortMode.recent.sorted([alpha, beta, gamma], commitDates: dates)
        var openedBeta = beta
        openedBeta.lastOpenedAt = Date(timeIntervalSince1970: 9_999)
        let after = ProjectSortMode.recent.sorted([alpha, openedBeta, gamma], commitDates: dates)

        XCTAssertEqual(before.map(\.title), ["Alpha", "Beta", "Gamma"])
        XCTAssertEqual(after.map(\.title), before.map(\.title), "点击项目不应改变「最近更新」顺序")
    }

    func testOpeningProjectsWithoutCommitDatesDoesNotChangeOrder() {
        let zeta = project("Zeta", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let alpha = project("Alpha", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let mid = project("Mid", lastOpenedAt: Date(timeIntervalSince1970: 100))

        let before = ProjectSortMode.recent.sorted([zeta, alpha, mid], commitDates: [:])
        let openedZeta = project("Zeta", lastOpenedAt: Date(timeIntervalSince1970: 9_999))
        let after = ProjectSortMode.recent.sorted([openedZeta, alpha, mid], commitDates: [:])

        XCTAssertEqual(before.map(\.title), after.map(\.title), "提交时间缺失时点击也不应改变顺序")
    }

    func testRecentModeUsesCommitDateInsteadOfLastOpened() {
        let a = project("A", lastOpenedAt: Date(timeIntervalSince1970: 999))
        let b = project("B", lastOpenedAt: Date(timeIntervalSince1970: 1))
        let dates: [UUID: Date] = [
            a.id: Date(timeIntervalSince1970: 100),
            b.id: Date(timeIntervalSince1970: 200),
        ]

        let sorted = ProjectSortMode.recent.sorted([a, b], commitDates: dates)

        XCTAssertEqual(sorted.map(\.title), ["B", "A"], "按提交时间排序，不看最近打开时间")
    }

    func testRecentModeKeepsPinnedProjectsFirst() {
        let pinned = project("Pinned", isPinned: true)
        let normal = project("Normal")
        let dates: [UUID: Date] = [
            pinned.id: Date(timeIntervalSince1970: 100),
            normal.id: Date(timeIntervalSince1970: 300),
        ]

        let sorted = ProjectSortMode.recent.sorted([normal, pinned], commitDates: dates)

        XCTAssertEqual(sorted.map(\.title), ["Pinned", "Normal"], "置顶项目始终在最前")
    }

    /// 回归：提交时间缓存被清空（例如侧边栏因工作区状态变化被重建）时，
    /// 「最近更新」不能退化成按名称排列——否则用户会看到列表瞬间变成
    /// 字母序，几秒后再跳回提交时间序。
    func testRecentModeKeepsInputOrderWhenCommitDatesAreMissing() {
        let zeta = project("Zeta")
        let alpha = project("Alpha")
        let mid = project("Mid")

        let sorted = ProjectSortMode.recent.sorted([zeta, alpha, mid], commitDates: [:])

        XCTAssertEqual(
            sorted.map(\.title),
            ["Zeta", "Alpha", "Mid"],
            "提交时间缺失时应保持原始（手动）顺序，而不是按名称重排"
        )
    }

    func testRecentModeBreaksEqualDatesByName() {
        let beta = project("Beta")
        let alpha = project("Alpha")
        let date = Date(timeIntervalSince1970: 100)
        let dates = [beta.id: date, alpha.id: date]

        let sorted = ProjectSortMode.recent.sorted([beta, alpha], commitDates: dates)

        XCTAssertEqual(sorted.map(\.title), ["Alpha", "Beta"], "时间相同时按名称排列")
    }

    // MARK: - Metadata

    func testOnlyRecentModeRequiresCommitActivity() {
        XCTAssertTrue(ProjectSortMode.recent.requiresCommitActivity)
        XCTAssertFalse(ProjectSortMode.manual.requiresCommitActivity)
        XCTAssertFalse(ProjectSortMode.name.requiresCommitActivity)
    }

    func testAllModesAreUniqueByRawValue() {
        let rawValues = ProjectSortMode.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count)
    }

    // MARK: - Helpers

    private func project(
        _ title: String,
        path: String? = nil,
        isPinned: Bool = false,
        lastOpenedAt: Date? = nil
    ) -> Project {
        Project(
            url: URL(fileURLWithPath: path ?? "/tmp/\(title)"),
            title: title,
            isPinned: isPinned,
            lastOpenedAt: lastOpenedAt
        )
    }
}
