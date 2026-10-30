import Foundation
import KitGit
import ProviderGit
import ProviderProjects
import XCTest
@testable import PluginWorktreeClean

/// 干净概览与变更列表必须共用同一份「工作区是否干净」的判定。
///
/// 两块内容各自判断时，一旦结论不一致就会同时「不占布局」，主内容区整块塌陷
/// （提交表单漂到面板中间、详情区留白）。
@MainActor
final class WorktreeCleanOwnerTests: XCTestCase {
    nonisolated private static let cleanStatus = GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main")
    nonisolated private static let dirtyStatus = GitWorktreeStatus(isClean: false, changeCount: 2, branch: "main")

    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for directory in temporaryDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        temporaryDirectories = []
        try super.tearDownWithError()
    }

    /// 干净概览的加载入口要求仓库目录真实存在，因此测试需要一个真实目录。
    private func makeRepositoryDirectory(_ name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorktreeCleanOwnerTests-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectories.append(directory)
        return directory
    }

    func testOwnerStartsPending() {
        let viewModel = WorktreeCleanViewModel(fallbackStatusLoader: { _ in Self.cleanStatus })

        XCTAssertEqual(viewModel.worktreeOwner, .pending)
    }

    /// 项目切换后归属必须回到「待定」：新仓库还没扫描出结论时，
    /// 干净概览不能提前亮起（否则会和变更列表同时占位或同时空）。
    func testOwnerResetsToPendingOnProjectChange() async throws {
        let first = try makeRepositoryDirectory("pending-first")
        let second = try makeRepositoryDirectory("pending-second")
        let viewModel = WorktreeCleanViewModel(fallbackStatusLoader: { _ in Self.cleanStatus })
        viewModel.handleProjectChanged(project: Project(url: first), hasSelectedCommit: false)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)

        viewModel.handleProjectChanged(project: Project(url: second), hasSelectedCommit: false)
        XCTAssertEqual(viewModel.worktreeOwner, .pending)
    }

    func testOwnerFollowsCleanStatus() async throws {
        let directory = try makeRepositoryDirectory("clean")
        let viewModel = WorktreeCleanViewModel(fallbackStatusLoader: { _ in Self.cleanStatus })
        viewModel.handleProjectChanged(project: Project(url: directory), hasSelectedCommit: false)

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)
        XCTAssertTrue(viewModel.isClean)
        XCTAssertTrue(viewModel.showsCleanState)
    }

    func testOwnerFollowsDirtyStatus() async throws {
        let directory = try makeRepositoryDirectory("dirty")
        let viewModel = WorktreeCleanViewModel(fallbackStatusLoader: { _ in Self.dirtyStatus })
        viewModel.handleProjectChanged(project: Project(url: directory), hasSelectedCommit: false)

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.worktreeOwner, .changes)
        XCTAssertFalse(viewModel.isClean)
        XCTAssertFalse(viewModel.showsCleanState)
    }

    /// 选中 commit 时干净概览隐藏（让位给 commit 详情），但归属判定本身
    /// 与 commit 选择无关，不应被改写——否则变更列表会被一起带偏。
    func testCleanStateYieldsToSelectedCommit() async throws {
        let directory = try makeRepositoryDirectory("commit-selected")
        let viewModel = WorktreeCleanViewModel(fallbackStatusLoader: { _ in Self.cleanStatus })
        let project = Project(url: directory)
        viewModel.handleProjectChanged(project: project, hasSelectedCommit: false)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)
        XCTAssertTrue(viewModel.showsCleanState)

        viewModel.handleProjectChanged(project: project, hasSelectedCommit: true)
        XCTAssertFalse(viewModel.showsCleanState)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)
    }
}
