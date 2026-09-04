import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderRootView
import XCTest
@testable import PluginGitDiff
@testable import ProviderRootView

@MainActor
final class GitDiffPluginTests: XCTestCase {
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
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        private let onCancel: () -> Void
        init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
        func cancel() { onCancel() }
    }

    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg \(hash)", author: "a", date: Date())
    }

    func testPluginMetadata() {
        let plugin = GitDiffPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.git-diff")
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.description.isEmpty)
    }

    // MARK: - onBoot / onShutdown（trailing pane 注入）

    func testOnBootRegistersTrailingPaneThroughRootViewProviding() throws {
        let kernel = KernelCoreContainer()
        let rootView = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, rootView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = GitDiffPlugin()
        try plugin.onBoot(kernel: kernel)

        // RootViewProviding 已注入 trailing pane（id 为插件面板 id）。
        XCTAssertEqual(rootView.trailingPane?.id, "\(plugin.id).trailing")
    }

    func testOnShutdownClearsTrailingPane() throws {
        let kernel = KernelCoreContainer()
        let rootView = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, rootView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = GitDiffPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertNotNil(rootView.trailingPane)

        try plugin.onShutdown(kernel: kernel)
        XCTAssertNil(rootView.trailingPane)
    }

    // MARK: - Observer → ViewModel wiring

    /// 组装与插件 onBoot 一致的 Observer→ViewModel 链路。
    private func makeObserver(
        projects: any ProjectProviding,
        viewModel: GitDiffViewModel
    ) -> GitDiffObserver {
        GitDiffObserver(
            projects: projects,
            onSelectionChanged: { [weak viewModel, weak projects] in
                guard let projects else { return }
                viewModel?.handleSelectionChanged(
                    commit: projects.currentCommit,
                    projectURL: projects.currentProject?.url,
                    file: projects.currentFile
                )
            },
            onProjectDataChanged: { [weak viewModel] in
                viewModel?.handleProjectDataChanged()
            }
        )
    }

    func testObserverTranslatesCommitSelectionToViewModel() {
        let projects = MockProjects()
        let viewModel = GitDiffViewModel()
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

    func testObserverTranslatesProjectDataChangedToRevision() {
        let projects = MockProjects()
        let viewModel = GitDiffViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        defer { observer.cancel() }

        XCTAssertEqual(viewModel.revision, 0)
        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.revision, 1)
        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.revision, 2)
    }

    func testObserverCancelStopsViewModelUpdates() {
        let projects = MockProjects()
        let viewModel = GitDiffViewModel()
        let observer = makeObserver(projects: projects, viewModel: viewModel)
        observer.cancel()

        projects.selectCommit(commit("x"))
        projects.notifyCommitSelectionChanged()
        XCTAssertNil(viewModel.selectedCommit)

        projects.notifyDataChanged()
        XCTAssertEqual(viewModel.revision, 0)
    }
}
