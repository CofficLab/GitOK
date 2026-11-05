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

    func testRecentModeFallsBackToLastOpenedWhenNoCommitDate() {
        let neverOpened = project("NeverOpened")
        let openedEarlier = project("OpenedEarlier", lastOpenedAt: Date(timeIntervalSince1970: 100))
        let openedLater = project("OpenedLater", lastOpenedAt: Date(timeIntervalSince1970: 200))

        let sorted = ProjectSortMode.recent.sorted(
            [neverOpened, openedEarlier, openedLater],
            commitDates: [:]
        )

        XCTAssertEqual(
            sorted.map(\.title),
            ["OpenedLater", "OpenedEarlier", "NeverOpened"],
            "没有提交时间时回退到最近打开时间"
        )
    }

    func testRecentModePrefersCommitDateOverLastOpened() {
        let project = project("Repo", lastOpenedAt: Date(timeIntervalSince1970: 999))
        let dates = [project.id: Date(timeIntervalSince1970: 100)]

        let date = ProjectSortMode.activityDate(for: project, commitDates: dates)

        XCTAssertEqual(date, Date(timeIntervalSince1970: 100))
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

    func testRecentModeIsStableForEqualDates() {
        let first = project("First")
        let second = project("Second")
        let date = Date(timeIntervalSince1970: 100)
        let dates = [first.id: date, second.id: date]

        let sorted = ProjectSortMode.recent.sorted([first, second], commitDates: dates)

        XCTAssertEqual(sorted.map(\.title), ["First", "Second"], "时间相同时保持原有顺序")
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
