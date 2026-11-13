import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 性能回归测试（GitOK issue #18）。
///
/// 这些测试锁定的是**结构性质**而非绝对耗时（CI 机器负载波动大，绝对阈值不可靠）：
/// - 视图读取派生状态不应触发重算；
/// - 排序时比较闭包只求值一次；
/// - 列表模型在输入不变时复用上一次结果。
@MainActor
final class ProjectListPerformanceTests: XCTestCase {

    /// 回归：分隔线索引此前是 computed property，在 `ForEach` 里被每个可见行
    /// 各访问一次，等于每个可见行都重排一次全量列表。
    ///
    /// 现在分隔线位置由列表模型一次算好，视图只做 id 比较。
    func testDividerLookupDoesNotRecomputeList() {
        let projects = (0..<1_000).map { index in
            Project(
                url: URL(fileURLWithPath: "/tmp/Repo\(index)"),
                title: "Repo\(index)",
                isPinned: index < 10
            )
        }

        let model = ProjectListModel()
        model.update(projects: projects, sortMode: .name, commitDates: [:])

        // 模拟「30 个可见行各查一次分隔线」：读取必须是廉价的等值比较，
        // 而不再触发任何过滤 / 排序。
        let start = Date()
        for _ in 0..<30 {
            _ = model.pinnedDividerAfterID
            _ = model.filteredProjects
        }
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(model.pinnedDividerAfterID, projects[9].id)
        XCTAssertLessThan(
            elapsed,
            0.05,
            "读取派生状态不应触发重复排序（耗时 \(elapsed)s）"
        )
    }

    /// 回归：稳定排序此前对每一对元素最多求值两次比较闭包
    /// （`areInIncreasingOrder(lhs, rhs)` 之后紧跟 `areInIncreasingOrder(rhs, lhs)`），
    /// 把 `localizedCaseInsensitiveCompare` 这类带 locale 归一化的比较开销翻倍。
    ///
    /// 检测方式是「比较闭包被调用的总次数」：旧实现必然出现反向重复求值，
    /// 总次数稳定高于「每对只求值一次」的上界。
    func testStableSortEvaluatesComparatorOncePerPair() {
        let projects = (0..<500).map { index in
            Project(
                url: URL(fileURLWithPath: "/tmp/Repo\(index)"),
                title: "Repo\(index)"
            )
        }

        var comparisons = 0
        var reverseCalls = 0
        var previous: (String, String)?
        let sorted = ProjectSortMode.stableSorted(projects) { lhs, rhs in
            comparisons += 1
            // 紧邻的反向重复求值 = 旧实现把同一对元素比较了两次的特征。
            if let previous, previous.0 == rhs.title, previous.1 == lhs.title {
                reverseCalls += 1
            }
            previous = (lhs.title, rhs.title)
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        }

        XCTAssertEqual(sorted.count, projects.count)
        XCTAssertGreaterThan(comparisons, 0, "比较闭包应被调用")
        XCTAssertEqual(
            reverseCalls,
            0,
            "比较闭包对同一对元素被反向重复求值 \(reverseCalls) 次（总比较 \(comparisons) 次），"
            + "排序开销因此被翻倍"
        )
    }

    /// 回归：列表模型在输入不变时不重算。
    func testUnchangedInputsDoNotRecompute() {
        let projects = (0..<500).map { index in
            Project(url: URL(fileURLWithPath: "/tmp/Repo\(index)"), title: "Repo\(index)")
        }

        let model = ProjectListModel()
        model.update(projects: projects, sortMode: .name, commitDates: [:])
        let firstResult = model.filteredProjects

        // 输入完全相同地重复更新：结果对象应保持同一份（未重新生成）。
        model.update(projects: projects, sortMode: .name, commitDates: [:])

        XCTAssertEqual(model.filteredProjects.count, firstResult.count)
        XCTAssertEqual(model.filteredProjects.map(\.id), firstResult.map(\.id))
    }

    /// 回归：排序在 1000 个项目规模下应在可接受时间内完成（此前每次视图刷新
    /// 都要重排一次，且比较闭包翻倍求值）。
    func testSortCompletesQuicklyForLargeList() {
        let projects = (0..<1_000).map { index in
            Project(url: URL(fileURLWithPath: "/tmp/Repo\(index)"), title: "Repo\(index)")
        }

        let start = Date()
        let sorted = ProjectSortMode.name.sorted(projects)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(sorted.count, 1_000)
        XCTAssertEqual(sorted.first?.title, "Repo0")
        XCTAssertLessThan(
            elapsed,
            1.0,
            "1000 个项目的单次排序耗时 \(elapsed)s，超出预期"
        )
    }
}
