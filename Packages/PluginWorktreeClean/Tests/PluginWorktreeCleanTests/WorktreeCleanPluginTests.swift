import Foundation
import KernelCore
import KitGit
import ProviderContentView
import ProviderProjects
import ProviderWorkspaceScene
import XCTest
@testable import PluginWorktreeClean
@testable import ProviderContentView

@MainActor
final class WorktreeCleanPluginTests: XCTestCase {

    /// 最小 ProjectProviding mock：记录观察者并支持主动广播事件，
    /// 同时维护 commit 选择状态（真实实现为 ProjectManager）。
    private final class MockProjects: ProjectProviding {
        var projects: [Project] = []
        var currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?
        private var observers: [(id: UUID, callback: (ProjectProvidingEvent) -> Void)] = []

        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle {
            let id = UUID()
            observers.append((id, callback))
            return MockHandle { [weak self] in
                self?.observers.removeAll { $0.id == id }
            }
        }
        func openProject(at url: URL) {}
        func closeCurrentProject() {}
        func addProject(at url: URL) {}
        func removeProject(id: UUID) {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func persist() {}
        func selectCommit(_ commit: GitCommit) { currentCommit = commit }
        func selectFile(_ path: String?) { currentFile = path }
        func clearCommitSelection() {
            currentCommit = nil
            currentFile = nil
            currentCommitFiles = nil
            isLoadingCommitFiles = false
            currentCommitFilesLoadError = nil
        }
        func notifyDataChanged() {
            let current = observers
            for observer in current { observer.callback(.dataChanged) }
        }
        /// 测试辅助：模拟「选中 commit 变化」并广播。
        func notifyCommitSelectionChanged() {
            let current = observers
            for observer in current { observer.callback(.commitSelectionChanged) }
        }
        /// 测试辅助：模拟「当前项目切换」并广播。
        func notifySelectionChanged() {
            let current = observers
            for observer in current {
                observer.callback(.selectionChanged(projectID: currentProject?.id))
            }
        }
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        private let onCancel: () -> Void
        init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
        func cancel() { onCancel() }
    }

    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg \(hash)", author: "a", date: Date())
    }

    // MARK: - Plugin metadata

    func testPluginMetadata() {
        let plugin = WorktreeCleanPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.worktree-clean")
        XCTAssertEqual(plugin.metadata.category, .project)
        // 内容贡献插件必须为 .required（内核会过滤 .disabled，不启动则不注册内容块）。
        XCTAssertEqual(plugin.metadata.policy, .required)
        XCTAssertTrue(plugin.dependencies.contains("com.coffic.lumi.plugin.projects"))
    }

    // MARK: - Content registration

    func testOnBootRegistersContentThroughContentViewProviding() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        try kernel.registerProvider(
            (any WorkspaceSceneProviding).self,
            DefaultWorkspaceSceneProvider()
        )

        let plugin = WorktreeCleanPlugin()
        try plugin.onBoot(kernel: kernel)

        let contentID = "\(plugin.id).content"
        XCTAssertTrue(contentView.registeredIDs.contains(contentID))
    }

    func testOnShutdownClearsContent() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        try kernel.registerProvider(
            (any WorkspaceSceneProviding).self,
            DefaultWorkspaceSceneProvider()
        )

        let plugin = WorktreeCleanPlugin()
        try plugin.onBoot(kernel: kernel)
        let contentID = "\(plugin.id).content"
        XCTAssertTrue(contentView.registeredIDs.contains(contentID))

        try plugin.onShutdown(kernel: kernel)
        XCTAssertFalse(contentView.registeredIDs.contains(contentID))
    }

    // MARK: - ViewModel state

    func testViewModelHidesWithoutProject() {
        let viewModel = WorktreeCleanViewModel()
        viewModel.handleProjectChanged(project: nil, hasSelectedCommit: false)
        XCTAssertNil(viewModel.project)
        XCTAssertFalse(viewModel.isClean)
    }

    func testViewModelHidesWhenCommitSelected() {
        let viewModel = WorktreeCleanViewModel()
        let project = Project(url: URL(fileURLWithPath: "/tmp/repo"))
        viewModel.handleProjectChanged(project: project, hasSelectedCommit: true)
        XCTAssertEqual(viewModel.project?.url, project.url)
        XCTAssertFalse(viewModel.isClean)
    }

    func testRefreshPolicyIgnoresIdenticalStatus() {
        let status = GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main")

        XCTAssertFalse(WorktreeCleanRefreshPolicy.didChange(previous: status, current: status))
    }

    func testRefreshPolicyDetectsChangedStatus() {
        let previous = GitWorktreeStatus(isClean: true, changeCount: 0, branch: "main")
        let current = GitWorktreeStatus(isClean: false, changeCount: 1, branch: "main")

        XCTAssertTrue(WorktreeCleanRefreshPolicy.didChange(previous: previous, current: current))
    }

    /// 回归：选中 commit 后，后续 dataChanged（提交 / 推送 / 分支切换 / 外部编辑）
    /// 不应重新点亮「工作区干净」视图——即使工作区实际是干净的。
    func testDataChangedDoesNotResurrectCleanViewAfterCommitSelected() async throws {
        let dir = try makeGitRepository()
        defer { try? FileManager.default.removeItem(at: dir) }

        let viewModel = WorktreeCleanViewModel()
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: false)
        await waitUntilClean(viewModel, expecting: true)
        XCTAssertTrue(viewModel.isClean)

        // 选中 commit → 干净视图隐藏。
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: true)
        XCTAssertFalse(viewModel.isClean)
        XCTAssertFalse(viewModel.isLoading)

        // dataChanged 事件不应重新点亮干净视图，也不应进入加载态。
        viewModel.handleDataChanged()
        XCTAssertFalse(viewModel.isClean)
        XCTAssertFalse(viewModel.isLoading)

        // 取消 commit 选择后，干净视图应能恢复正常。
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: false)
        await waitUntilClean(viewModel, expecting: true)
        XCTAssertTrue(viewModel.isClean)
    }

    /// 回归：已有快照后收到无实际状态变化的 dataChanged，只做后台校验，
    /// 不应让 ViewModel 重新进入 loading 状态或改变干净视图。
    func testDataChangedKeepsExistingStateWhileRefreshingIdenticalStatus() async throws {
        let dir = try makeGitRepository()
        defer { try? FileManager.default.removeItem(at: dir) }

        let viewModel = WorktreeCleanViewModel()
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: false)
        await waitUntilClean(viewModel, expecting: true)

        viewModel.handleDataChanged()
        XCTAssertTrue(viewModel.isClean)
        XCTAssertFalse(viewModel.isLoading)

        // 等待后台校验完成，确保相同快照不会改变最终状态。
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertTrue(viewModel.isClean)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Cleanliness detection (real git repo)

    /// 在临时目录初始化一个空 git 仓库并返回其 URL（无需网络）。
    private func makeGitRepository() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorktreeCleanTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init"]
        process.currentDirectoryURL = dir
        try process.run()
        process.waitUntilExit()
        return dir
    }

    func testViewModelDetectsCleanRepository() async throws {
        let dir = try makeGitRepository()
        defer { try? FileManager.default.removeItem(at: dir) }

        let viewModel = WorktreeCleanViewModel()
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: false)

        // GitStatusLoader 在后台任务执行，等待状态收敛。
        await waitUntilClean(viewModel, expecting: true)
        XCTAssertTrue(viewModel.isClean)
    }

    func testViewModelDetectsDirtyRepository() async throws {
        let dir = try makeGitRepository()
        defer { try? FileManager.default.removeItem(at: dir) }

        // 制造一个未跟踪文件 → 工作区变脏。
        try "hello".write(to: dir.appendingPathComponent("dirty.txt"), atomically: true, encoding: .utf8)

        let viewModel = WorktreeCleanViewModel()
        viewModel.handleProjectChanged(project: Project(url: dir), hasSelectedCommit: false)

        await waitUntilClean(viewModel, expecting: false)
        XCTAssertFalse(viewModel.isClean)
    }

    /// 轮询等待 viewModel.isClean 收敛到期望值（后台 git 任务完成）。
    private func waitUntilClean(_ viewModel: WorktreeCleanViewModel, expecting: Bool) async {
        for _ in 0..<100 {
            if viewModel.isClean == expecting && !viewModel.isLoading {
                return
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}
