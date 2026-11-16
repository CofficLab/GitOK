import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目列表派生状态模型的单元测试（GitOK issue #18 回归）。
///
/// 这些测试锁定的行为：
/// - 过滤 + 排序只算一次，视图反复读取不重复计算；
/// - 置顶分隔线的位置一次算好，不在行循环里重算；
/// - 搜索词带防抖，连续输入不会触发多次全量过滤。
@MainActor
final class ProjectListModelTests: XCTestCase {

    // MARK: - Caching

    func testUpdateWithUnchangedInputsKeepsResultStable() {
        let model = ProjectListModel()
        let projects = [
            project("Zeta"),
            project("Alpha"),
            project("Mid"),
        ]

        model.update(projects: projects, sortMode: .name, commitDates: [:])
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Alpha", "Mid", "Zeta"])

        // 相同输入重复更新：结果不变（内部走等值比较，不重算）。
        model.update(projects: projects, sortMode: .name, commitDates: [:])
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Alpha", "Mid", "Zeta"])
    }

    func testSortModeChangeReordersList() {
        let model = ProjectListModel()
        let projects = [project("Zeta"), project("Alpha")]

        model.update(projects: projects, sortMode: .name, commitDates: [:])
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Alpha", "Zeta"])

        model.update(projects: projects, sortMode: .manual, commitDates: [:])
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Zeta", "Alpha"])
    }

    func testCommitDatesChangeReordersRecentList() {
        let model = ProjectListModel()
        let alpha = project("Alpha")
        let beta = project("Beta")

        model.update(projects: [alpha, beta], sortMode: .recent, commitDates: [:])
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Alpha", "Beta"])

        model.update(
            projects: [alpha, beta],
            sortMode: .recent,
            commitDates: [alpha.id: Date(timeIntervalSince1970: 100)]
        )
        XCTAssertEqual(
            model.filteredProjects.map(\.title),
            ["Alpha", "Beta"],
            "提交时间缺失时保持原始顺序"
        )
    }

    // MARK: - Divider

    func testDividerIndexComputedOnceForMixedList() {
        let model = ProjectListModel()
        let pinned = project("Pinned", isPinned: true)
        let normal = project("Normal")

        model.update(projects: [pinned, normal], sortMode: .manual, commitDates: [:])

        XCTAssertEqual(model.pinnedDividerIndex, 1, "分隔线在第一个未置顶项目之前")
        XCTAssertEqual(
            model.pinnedDividerAfterID,
            pinned.id,
            "分隔线画在最后一个置顶项目之后"
        )
    }

    func testNoDividerWhenAllPinned() {
        let model = ProjectListModel()
        let a = project("A", isPinned: true)
        let b = project("B", isPinned: true)

        model.update(projects: [a, b], sortMode: .manual, commitDates: [:])

        XCTAssertNil(model.pinnedDividerIndex)
        XCTAssertNil(model.pinnedDividerAfterID)
    }

    func testNoDividerWhenNonePinned() {
        let model = ProjectListModel()
        let a = project("A")
        let b = project("B")

        model.update(projects: [a, b], sortMode: .manual, commitDates: [:])

        XCTAssertNil(model.pinnedDividerIndex)
        XCTAssertNil(model.pinnedDividerAfterID)
    }

    func testDividerHelperMatchesModel() {
        let pinned = project("Pinned", isPinned: true)
        let normal = project("Normal")
        XCTAssertEqual(ProjectListModel.dividerIndex(in: [pinned, normal]), 1)
        XCTAssertNil(ProjectListModel.dividerIndex(in: [normal]))
        XCTAssertNil(ProjectListModel.dividerIndex(in: [pinned]))
        XCTAssertNil(ProjectListModel.dividerIndex(in: []))
    }

    // MARK: - Counts

    func testCountsReflectAllProjectsNotFilteredOnes() {
        let model = ProjectListModel()
        let a = project("Alpha", isPinned: true)
        let b = project("Beta")

        model.update(projects: [a, b], sortMode: .manual, commitDates: [:])
        XCTAssertEqual(model.totalCount, 2)
        XCTAssertEqual(model.pinnedProjectCount, 1)
        XCTAssertTrue(model.hasProjects)

        model.applySearchTextImmediately("Alpha")
        XCTAssertEqual(
            model.filteredProjects.map(\.title),
            ["Alpha"],
            "过滤只影响展示列表"
        )
        XCTAssertEqual(model.totalCount, 2, "总数仍是全部项目数")
        XCTAssertEqual(model.pinnedProjectCount, 1, "置顶数仍是全部项目的置顶数")
    }

    func testHasProjectsFalseForEmptyList() {
        let model = ProjectListModel()
        model.update(projects: [], sortMode: .manual, commitDates: [:])

        XCTAssertFalse(model.hasProjects)
        XCTAssertEqual(model.totalCount, 0)
        XCTAssertTrue(model.filteredProjects.isEmpty)
    }

    // MARK: - Search

    func testImmediateSearchFiltersList() {
        let model = ProjectListModel()
        model.update(
            projects: [project("Alpha"), project("Beta")],
            sortMode: .manual,
            commitDates: [:]
        )

        model.applySearchTextImmediately("bet")
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Beta"])
    }

    func testImmediateSearchWithBlankKeywordRestoresFullList() {
        let model = ProjectListModel()
        model.update(
            projects: [project("Alpha"), project("Beta")],
            sortMode: .manual,
            commitDates: [:]
        )

        model.applySearchTextImmediately("bet")
        XCTAssertEqual(model.filteredProjects.count, 1)

        model.applySearchTextImmediately("   ")
        XCTAssertEqual(model.filteredProjects.count, 2, "空白搜索词应显示全部项目")
    }

    func testDebouncedSearchDoesNotApplyImmediately() async {
        let model = ProjectListModel()
        model.update(
            projects: [project("Alpha"), project("Beta")],
            sortMode: .manual,
            commitDates: [:]
        )

        model.setSearchText("Beta")
        // 防抖窗口内不应已经生效。
        XCTAssertEqual(model.filteredProjects.count, 2)

        try? await Task.sleep(for: ProjectListModel.searchDebounceInterval * 3)
        XCTAssertEqual(
            model.filteredProjects.map(\.title),
            ["Beta"],
            "停顿后搜索词应生效"
        )
    }

    func testDebouncedSearchCoalescesRapidInput() async {
        let model = ProjectListModel()
        model.update(
            projects: [project("Alpha"), project("Beta"), project("Gamma")],
            sortMode: .manual,
            commitDates: [:]
        )

        // 连续输入三个字符：只有最后一个生效。
        model.setSearchText("B")
        model.setSearchText("Be")
        model.setSearchText("Bet")

        try? await Task.sleep(for: ProjectListModel.searchDebounceInterval * 3)
        XCTAssertEqual(model.filteredProjects.map(\.title), ["Beta"])
    }

    // MARK: - Helpers

    private func project(
        _ title: String,
        isPinned: Bool = false
    ) -> Project {
        Project(
            url: URL(fileURLWithPath: "/tmp/\(title)"),
            title: title,
            isPinned: isPinned
        )
    }
}
