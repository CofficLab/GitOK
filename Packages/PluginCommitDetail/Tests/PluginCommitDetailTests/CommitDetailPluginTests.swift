import Foundation
import KernelCore
import KitGit
import ProviderContentView
import ProviderProjects
import XCTest
@testable import PluginCommitDetail
@testable import ProviderContentView

@MainActor
final class CommitDetailPluginTests: XCTestCase {
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
        /// 测试辅助：模拟「选中 commit 变化」并广播（真实 ProjectManager 在
        /// selectCommit 后自动广播）。
        func notifyCommitSelectionChanged() {
            let current = observers
            for observer in current { observer.callback(.commitSelectionChanged) }
        }
        /// 测试辅助：模拟「当前文件变化」并广播。
        func notifyCurrentFileChanged() {
            let current = observers
            for observer in current { observer.callback(.currentFileChanged) }
        }
        /// 测试辅助：模拟「当前项目切换」并广播（真实 ProjectManager 在
        /// setCurrentProject / openProject / closeCurrentProject 后自动广播）。
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

    func testOnBootRegistersContentThroughContentViewProviding() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = CommitDetailPlugin()
        try plugin.onBoot(kernel: kernel)

        // ContentViewProviding 已注入内容块（id 为插件内容 id）。
        let contentID = "\(plugin.id).content"
        XCTAssertTrue(contentView.registeredIDs.contains(contentID))
        // ContentViewProviding 已注入内容（CommitDetailView）。
        let host = contentView.makeContentView()
        XCTAssertFalse(String(describing: host).isEmpty)
    }

    func testOnShutdownClearsContent() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = CommitDetailPlugin()
        try plugin.onBoot(kernel: kernel)
        let contentID = "\(plugin.id).content"
        XCTAssertTrue(contentView.registeredIDs.contains(contentID))

        try plugin.onShutdown(kernel: kernel)
        XCTAssertFalse(contentView.registeredIDs.contains(contentID))
    }

    // MARK: - Observer → ViewModel wiring

    /// 组装与插件 onBoot 一致的 Observer→ViewModel 链路。
    private func makeObserver(
        projects: any ProjectProviding,
        viewModel: CommitDetailViewModel
    ) -> CommitDetailObserver {
        CommitDetailObserver(
            projects: projects,
            gitWatch: nil,
            viewModel: viewModel
        )
    }

    func testObserverSynchronizesInitialProvidingSnapshot() {
        let projects = MockProjects()
        let url = URL(fileURLWithPath: "/tmp/repo")
        let selected = commit("initial")
        let change = GitFileChange(
            path: "Sources/App.swift",
            status: .modified,
            addedLines: 2,
            deletedLines: 1
        )
        projects.currentProject = Project(url: url, lastOpenedAt: Date())
        projects.currentCommit = selected
        projects.currentFile = change.path
        projects.currentCommitFiles = [change]
        projects.isLoadingCommitFiles = false

        let viewModel = CommitDetailViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        defer { observer.cancel() }

        XCTAssertEqual(viewModel.selectedCommit?.hash, selected.hash)
        XCTAssertEqual(viewModel.selectedProjectURL, url)
        XCTAssertEqual(viewModel.selectedFile, change.path)
        XCTAssertEqual(viewModel.currentCommitFiles, [change])
    }

    func testObserverTranslatesCommitSelectionToViewModel() {
        let projects = MockProjects()
        let viewModel = CommitDetailViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        defer { observer.cancel() }

        let url = URL(fileURLWithPath: "/tmp/repo")
        projects.currentProject = Project(url: url, lastOpenedAt: Date())
        projects.selectCommit(commit("a"))
        projects.notifyCommitSelectionChanged()
        XCTAssertEqual(viewModel.selectedCommit?.hash, "a")
        XCTAssertEqual(viewModel.selectedProjectURL, url)

        projects.selectFile("src/a.swift")
        projects.notifyCurrentFileChanged()
        XCTAssertEqual(viewModel.selectedFile, "src/a.swift")

        projects.clearCommitSelection()
        projects.notifyCommitSelectionChanged()
        XCTAssertNil(viewModel.selectedCommit)
        XCTAssertNil(viewModel.selectedFile)
        // selectedProjectURL 语义为「当前项目」，不因清除 commit 选择而清空。
        XCTAssertEqual(viewModel.selectedProjectURL, url)
    }

    func testObserverTranslatesProjectDataChangedToWorktreeRevision() {
        let projects = MockProjects()
        let viewModel = CommitDetailViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        defer { observer.cancel() }

        XCTAssertEqual(viewModel.worktreeRevision, 0)
        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.worktreeRevision, 1)
        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.worktreeRevision, 2)
    }

    /// 切换 / 打开 / 关闭项目时，即使没有选中 commit（场景 B），
    /// 也应递增 worktreeRevision 触发工作区 / 仓库信息视图重载，
    /// 避免残留旧项目的仓库信息。
    func testObserverTranslatesSelectionChangedToWorktreeRevision() {
        let projects = MockProjects()
        let viewModel = CommitDetailViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        defer { observer.cancel() }

        XCTAssertEqual(viewModel.worktreeRevision, 0)
        // 场景 B：未选中任何 commit，直接切换项目。
        XCTAssertNil(viewModel.selectedCommit)
        let url = URL(fileURLWithPath: "/tmp/selected-project")
        projects.currentProject = Project(url: url, lastOpenedAt: Date())
        projects.notifySelectionChanged()
        XCTAssertEqual(viewModel.worktreeRevision, 1)
        XCTAssertEqual(viewModel.selectedProjectURL, url)

        // 关闭项目同样触发重载。
        projects.notifySelectionChanged()
        XCTAssertEqual(viewModel.worktreeRevision, 2)
    }

    func testObserverCancelStopsViewModelUpdates() {
        let projects = MockProjects()
        let viewModel = CommitDetailViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        observer.cancel()

        projects.selectCommit(commit("x"))
        projects.notifyCommitSelectionChanged()
        XCTAssertNil(viewModel.selectedCommit)

        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.worktreeRevision, 0)
    }

    // MARK: - Refresh policy（对齐 CommitListRefreshPolicy）

    func testRefreshPolicyOnlyMarksNewFilePaths() {
        let existing = [
            GitFileChange(path: "Sources/a.swift", status: .modified, addedLines: 2, deletedLines: 1),
            GitFileChange(path: "Sources/b.swift", status: .added, addedLines: 3, deletedLines: 0),
        ]
        let refreshed = [
            GitFileChange(path: "Sources/c.swift", status: .added, addedLines: 5, deletedLines: 0),
            existing[0],
            existing[1],
        ]

        XCTAssertEqual(
            CommitFilesRefreshPolicy.insertedFilePaths(previous: existing, current: refreshed),
            ["Sources/c.swift"]
        )
    }

    // MARK: - ViewModel 刷新保留与动画标记

    private func change(_ path: String, status: GitFileChange.Status = .modified) -> GitFileChange {
        GitFileChange(path: path, status: status, addedLines: 1, deletedLines: 0)
    }

    /// 加载新 commit 期间（files == nil）：保留上一份列表，不整表闪烁。
    func testViewModelKeepsPreviousFilesWhileLoading() {
        let viewModel = CommitDetailViewModel()
        let old = [change("Sources/a.swift")]

        viewModel.handleCommitFilesChanged(files: old, isLoading: false, loadError: nil, commitHash: "aaa")
        XCTAssertEqual(viewModel.currentCommitFiles, old)
        XCTAssertEqual(viewModel.filesCommitHash, "aaa")

        // 选中新 commit 后加载中：旧列表保留，仅标记 loading。
        viewModel.handleCommitFilesChanged(files: nil, isLoading: true, loadError: nil, commitHash: "bbb")
        XCTAssertEqual(viewModel.currentCommitFiles, old, "加载期间应保留上一份列表")
        XCTAssertTrue(viewModel.isLoadingCommitFiles)
        XCTAssertEqual(viewModel.filesCommitHash, "aaa", "展示中的文件仍归属旧 commit")
    }

    /// 同 commit 刷新：只标记新增行的动画路径，既有行不参与动画。
    func testViewModelMarksInsertedPathsOnSameCommitRefresh() {
        let viewModel = CommitDetailViewModel()
        let existing = [change("Sources/a.swift"), change("Sources/b.swift")]

        viewModel.handleCommitFilesChanged(files: existing, isLoading: false, loadError: nil, commitHash: "aaa")
        let refreshed = [change("Sources/c.swift"), existing[0], existing[1]]
        viewModel.handleCommitFilesChanged(files: refreshed, isLoading: false, loadError: nil, commitHash: "aaa")

        XCTAssertEqual(viewModel.animatedFilePaths, ["Sources/c.swift"])
        XCTAssertEqual(viewModel.currentCommitFiles, refreshed)
    }

    /// 跨 commit 切换：整表替换，全部新行标记动画。
    func testViewModelMarksAllPathsOnCommitSwitch() {
        let viewModel = CommitDetailViewModel()
        viewModel.handleCommitFilesChanged(files: [change("Sources/a.swift")], isLoading: false, loadError: nil, commitHash: "aaa")

        let switched = [change("Sources/x.swift"), change("Sources/y.swift")]
        viewModel.handleCommitFilesChanged(files: switched, isLoading: false, loadError: nil, commitHash: "bbb")

        XCTAssertEqual(viewModel.animatedFilePaths, ["Sources/x.swift", "Sources/y.swift"])
        XCTAssertEqual(viewModel.currentCommitFiles, switched)
        XCTAssertEqual(viewModel.filesCommitHash, "bbb")
    }

    /// 首次加载（此前无任何数据）：不播动画，直接呈现。
    func testViewModelFirstLoadDoesNotAnimate() {
        let viewModel = CommitDetailViewModel()
        let files = [change("Sources/a.swift")]

        viewModel.handleCommitFilesChanged(files: files, isLoading: false, loadError: nil, commitHash: "aaa")

        XCTAssertEqual(viewModel.currentCommitFiles, files)
        XCTAssertTrue(viewModel.animatedFilePaths.isEmpty)
    }

    /// 切换到无变动 / 加载失败的 commit：直接呈现空结果，不播行级动画。
    func testViewModelSwitchToEmptyResultDoesNotAnimate() {
        let viewModel = CommitDetailViewModel()
        viewModel.handleCommitFilesChanged(files: [change("Sources/a.swift")], isLoading: false, loadError: nil, commitHash: "aaa")

        viewModel.handleCommitFilesChanged(files: [], isLoading: false, loadError: "boom", commitHash: "bbb")

        XCTAssertEqual(viewModel.currentCommitFiles, [])
        XCTAssertTrue(viewModel.animatedFilePaths.isEmpty)
        XCTAssertEqual(viewModel.commitFilesLoadError, "boom")
    }

    /// 退出 commit 详情（commit == nil）：清空上一 commit 的变动文件。
    func testViewModelClearsFilesWhenSelectionCleared() {
        let viewModel = CommitDetailViewModel()
        viewModel.handleCommitFilesChanged(files: [change("Sources/a.swift")], isLoading: false, loadError: nil, commitHash: "aaa")

        viewModel.handleSelectionChanged(commit: nil, projectURL: URL(fileURLWithPath: "/tmp/repo"), file: nil)

        XCTAssertNil(viewModel.currentCommitFiles)
        XCTAssertNil(viewModel.filesCommitHash)
        XCTAssertTrue(viewModel.animatedFilePaths.isEmpty)
        XCTAssertFalse(viewModel.isLoadingCommitFiles)
    }
}
