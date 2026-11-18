import Foundation
import KernelCore
import KitGit
import ProviderCloneRepository
import ProviderProjects
import GitOKProviderRootView
import ProviderRootView
import SwiftUI
import XCTest
@testable import GitOKPluginRootView

@MainActor
final class PluginRootViewTests: XCTestCase {

    // MARK: - Mock

    /// 最小 ProjectProviding mock：维护项目列表并支持主动广播。
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
        func renameProject(id: UUID, newName: String) throws {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func persist() {}
        func selectCommit(_ commit: GitCommit) {}
        func selectFile(_ path: String?) {}
        func clearCommitSelection() {}
        func notifyDataChanged() {}

        /// 测试辅助：广播「项目列表变化」事件。
        func notifyProjectsChanged() {
            let current = observers
            for observer in current { observer.callback(.projectsChanged) }
        }

        /// 测试辅助：广播当前项目变化事件。
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

    /// 创建一个临时目录并放入 `.git` 子目录，模拟真实 Git 仓库；测试结束自动清理。
    @MainActor
    private func makeTempGitRepository() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: url.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    @MainActor
    private final class MockCloneRepository: CloneRepositoryProviding {
        var activeDestinations: Set<URL> = []
        var failedDestinations: Set<URL> = []
        private var observers: [(id: UUID, callback: (CloneRepositoryEvent) -> Void)] = []

        var tasks: [CloneTask] {
            activeDestinations.map {
                CloneTask(
                    remoteURL: "https://example.com/repository.git",
                    destination: $0,
                    repositoryName: "repository",
                    status: .cloning
                )
            } + failedDestinations.map {
                CloneTask(
                    remoteURL: "https://example.com/repository.git",
                    destination: $0,
                    repositoryName: "repository",
                    status: .failed,
                    errorMessage: "remote authentication required"
                )
            }
        }

        func isCloning(for projectURL: URL) -> Bool {
            activeDestinations.contains(projectURL.standardizedFileURL)
        }

        func task(for destination: URL) -> CloneTask? {
            tasks.first { $0.destination.standardizedFileURL == destination.standardizedFileURL }
        }

        func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask {
            fatalError("Not used by this test double")
        }

        func cancel(taskID: UUID) {}

        func retry(taskID: UUID) throws -> CloneTask {
            fatalError("Not used by this test double")
        }

        @discardableResult
        func addObserver(
            _ callback: @escaping (CloneRepositoryEvent) -> Void
        ) -> any CloneRepositoryObserverHandle {
            let id = UUID()
            observers.append((id: id, callback: callback))
            return MockCloneHandle { [weak self] in
                self?.observers.removeAll { $0.id == id }
            }
        }

        func notify(_ event: CloneRepositoryEvent) {
            for observer in observers {
                observer.callback(event)
            }
        }
    }

    @MainActor
    private final class MockCloneHandle: CloneRepositoryObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() {
            onCancel()
        }
    }

    // MARK: - 基本元数据

    func testPluginMetadata() {
        let plugin = RootViewPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.root-view")
        XCTAssertEqual(plugin.order, 5)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.description.isEmpty)
    }

    // MARK: - 宿主 Provider 接管

    func testOnBootAdoptsHostRegisteredProvider() throws {
        let kernel = KernelCoreContainer()
        let hostProvider = GitOKRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, hostProvider)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertTrue(resolved === hostProvider)
        XCTAssertTrue(plugin.provider === hostProvider)
    }

    func testOnShutdownKeepsHostProviderRegistered() throws {
        let kernel = KernelCoreContainer()
        let hostProvider = GitOKRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, hostProvider)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        // 根视图归宿主所有：插件卸载不注销、不替换。
        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertTrue(resolved === hostProvider)
        XCTAssertNil(plugin.provider)
    }

    func testOnBootWithoutHostProviderSkipsGating() throws {
        let kernel = KernelCoreContainer()
        // 宿主注册的是基类而非 GitOKRootViewProvider：插件优雅降级。
        try kernel.registerProvider(
            (any RootViewProviding).self,
            GitOKProviderRootView.DefaultRootViewProvider()
        )

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertNil(plugin.provider)
    }

    // MARK: - 委托链路

    func testProviderDelegatesSetViews() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)

        provider.setToolbarView(AnyView(Text("Toolbar")))
        provider.setSidebarView(AnyView(Text("Sidebar")))
        provider.setContentView(AnyView(Text("Content")))
        provider.setStatusBarView(AnyView(Text("Status")))
        provider.setContentHeaderView(AnyView(Text("Header")))
        provider.setContentFooterView(AnyView(Text("Footer")))

        let rootView = provider.makeRootView()
        XCTAssertNotNil(rootView)
    }

    // MARK: - Overlay 操作

    func testProviderOverlayOperations() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)

        // 手动添加额外 overlay。
        provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 100) { content in content },
        ])
        XCTAssertEqual(provider.overlays.count, 1)

        // 同 id 不重复注册。
        provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 200) { content in content },
        ])
        XCTAssertEqual(provider.overlays.count, 1)

        provider.removeOverlays(ids: ["test-overlay"])
        XCTAssertEqual(provider.overlays.count, 0)
    }

    // MARK: - Rail / Content 显隐

    func testProviderRailViewOperations() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)

        XCTAssertTrue(provider.isRailViewVisible)
        provider.setRailViewVisible(false)
        XCTAssertFalse(provider.isRailViewVisible)
        provider.setRailViewVisible(true)
        XCTAssertTrue(provider.isRailViewVisible)
    }

    func testProviderContentViewHidden() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)

        XCTAssertFalse(provider.isContentViewHidden)
        provider.setContentViewHidden(true)
        XCTAssertTrue(provider.isContentViewHidden)
    }

    // MARK: - 工作区状态门控

    /// 启动时没有当前项目 → 根布局进入 noProject 状态。
    func testOnBootSetsNoProjectWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(try XCTUnwrap(plugin.provider).workspaceState, .noProject)
    }

    /// 当前项目目录不存在 → 根布局进入 projectMissing 状态。
    func testOnBootSetsMissingProjectWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        mockProjects.projects = [
            Project(url: URL(fileURLWithPath: "/definitely/missing/repo"), title: "Missing"),
        ]
        mockProjects.currentProject = mockProjects.projects[0]
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(
            try XCTUnwrap(plugin.provider).workspaceState,
            .projectMissing(path: "/definitely/missing/repo")
        )
    }

    /// 目标目录尚未创建但存在 active clone 任务 → 根布局显示克隆中视图。
    func testOnBootSetsCloningWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let project = Project(
            url: URL(fileURLWithPath: "/definitely/missing/clone-repository"),
            title: "Clone repository"
        )
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        let mockCloneRepository = MockCloneRepository()
        mockCloneRepository.activeDestinations = [project.url]

        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)
        try kernel.registerProvider((any CloneRepositoryProviding).self, mockCloneRepository)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(try XCTUnwrap(plugin.provider).workspaceState, .cloning)
    }

    /// clone 结束后任务事件驱动根布局重新判断目录状态。
    func testCloneEventUpdatesWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let project = Project(
            url: URL(fileURLWithPath: "/definitely/missing/clone-repository"),
            title: "Clone repository"
        )
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        let mockCloneRepository = MockCloneRepository()
        mockCloneRepository.activeDestinations = [project.url]

        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)
        try kernel.registerProvider((any CloneRepositoryProviding).self, mockCloneRepository)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)
        XCTAssertEqual(provider.workspaceState, .cloning)

        mockCloneRepository.activeDestinations.removeAll()
        mockCloneRepository.notify(.tasksChanged)

        XCTAssertEqual(
            provider.workspaceState,
            .projectMissing(path: project.url.path)
        )
    }

    /// 当前项目目录存在且是 Git 仓库 → 根布局进入 ready 状态。
    func testOnBootSetsReadyWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let project = Project(url: try makeTempGitRepository(), title: "Temp")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(try XCTUnwrap(plugin.provider).workspaceState, .ready)
    }

    /// 失败任务即使留下 `.git` 目录，也必须阻止 Git 工作区挂载。
    func testFailedCloneWithGitDirectoryUsesCloneFailedWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let project = Project(url: try makeTempGitRepository(), title: "Failed clone")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        let mockCloneRepository = MockCloneRepository()
        mockCloneRepository.failedDestinations = [project.url]

        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)
        try kernel.registerProvider((any CloneRepositoryProviding).self, mockCloneRepository)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(
            try XCTUnwrap(plugin.provider).workspaceState,
            .cloneFailed
        )
    }

    /// 当前项目目录存在但不是 Git 仓库 → 根布局进入 notGitRepository 状态。
    func testOnBootSetsNotGitRepositoryWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        let project = Project(url: url, title: "Not Git")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(
            try XCTUnwrap(plugin.provider).workspaceState,
            .notGitRepository(path: url.path)
        )
    }

    /// 项目切换时状态同步更新，业务工作区无需先渲染一次。
    func testWorkspaceStateUpdatesOnProjectSelectionChange() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, GitOKRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = try XCTUnwrap(plugin.provider)
        XCTAssertEqual(provider.workspaceState, .noProject)

        let project = Project(url: try makeTempGitRepository(), title: "Temp")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        mockProjects.notifySelectionChanged()
        XCTAssertEqual(provider.workspaceState, .ready)

        mockProjects.currentProject = Project(
            url: URL(fileURLWithPath: "/definitely/missing/repo"),
            title: "Missing"
        )
        mockProjects.notifySelectionChanged()
        XCTAssertEqual(
            provider.workspaceState,
            .projectMissing(path: "/definitely/missing/repo")
        )
    }

    /// onShutdown 后 observer 被取消，项目事件不再驱动工作区状态。
    func testOnShutdownCancelsObserverAndResetsWorkspace() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let hostProvider = GitOKRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, hostProvider)
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertEqual(hostProvider.workspaceState, .noProject)

        try plugin.onShutdown(kernel: kernel)

        let project = Project(url: try makeTempGitRepository(), title: "Temp")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        mockProjects.notifySelectionChanged()
        XCTAssertEqual(hostProvider.workspaceState, .noProject)
    }

    /// 无 ProjectProviding 时 onBoot 不崩溃（优雅降级）。
    func testOnBootWithoutProjectProvidingDoesNotCrash() throws {
        let kernel = KernelCoreContainer()
        let hostProvider = GitOKRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, hostProvider)
        // 不注册 ProjectProviding。

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 即使没有 ProjectProviding，宿主 Provider 接管仍然成功。
        XCTAssertTrue(plugin.provider === hostProvider)
        XCTAssertTrue(kernel.resolveProvider((any RootViewProviding).self) === hostProvider)
    }
}