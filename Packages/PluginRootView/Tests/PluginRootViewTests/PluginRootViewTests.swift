import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderRootView
import SwiftUI
import XCTest
@testable import PluginRootView

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

    // MARK: - 基本元数据

    func testPluginMetadata() {
        let plugin = RootViewPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.root-view")
        XCTAssertEqual(plugin.order, 5)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.description.isEmpty)
    }

    // MARK: - 替换式注册

    func testOnBootReplacesDefaultProvider() throws {
        let kernel = KernelCoreContainer()
        let defaultProvider = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, defaultProvider)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertTrue(resolved is GitOKRootViewProvider)
        XCTAssertFalse(resolved === defaultProvider)
        XCTAssertTrue(resolved === plugin.provider)
    }

    func testOnShutdownRestoresDefaultProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(kernel.resolveProvider((any RootViewProviding).self) is GitOKRootViewProvider)

        try plugin.onShutdown(kernel: kernel)
        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertFalse(resolved is GitOKRootViewProvider)
        XCTAssertNotNil(resolved)
    }

    // MARK: - 委托链路

    func testProviderDelegatesSetViews() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        plugin.provider.setToolbarView(AnyView(Text("Toolbar")))
        plugin.provider.setSidebarView(AnyView(Text("Sidebar")))
        plugin.provider.setContentView(AnyView(Text("Content")))
        plugin.provider.setStatusBarView(AnyView(Text("Status")))
        plugin.provider.setContentHeaderView(AnyView(Text("Header")))
        plugin.provider.setContentFooterView(AnyView(Text("Footer")))

        let rootView = plugin.provider.makeRootView()
        XCTAssertNotNil(rootView)
    }

    // MARK: - Overlay 操作

    func testProviderOverlayOperations() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 手动添加额外 overlay。
        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 100) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 1)

        // 同 id 不重复注册。
        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 200) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 1)

        plugin.provider.removeOverlays(ids: ["test-overlay"])
        XCTAssertEqual(plugin.provider.overlays.count, 0)
    }

    // MARK: - Rail / Content 显隐

    func testProviderRailViewOperations() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(plugin.provider.isRailViewVisible)
        plugin.provider.setRailViewVisible(false)
        XCTAssertFalse(plugin.provider.isRailViewVisible)
        plugin.provider.setRailViewVisible(true)
        XCTAssertTrue(plugin.provider.isRailViewVisible)
    }

    func testProviderContentViewHidden() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertFalse(plugin.provider.isContentViewHidden)
        plugin.provider.setContentViewHidden(true)
        XCTAssertTrue(plugin.provider.isContentViewHidden)
    }

    // MARK: - 工作区状态门控

    /// 启动时没有当前项目 → 根布局进入 noProject 状态。
    func testOnBootSetsNoProjectWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(plugin.provider.workspaceState, .noProject)
    }

    /// 当前项目目录不存在 → 根布局进入 projectMissing 状态。
    func testOnBootSetsMissingProjectWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        mockProjects.projects = [
            Project(url: URL(fileURLWithPath: "/definitely/missing/repo"), title: "Missing"),
        ]
        mockProjects.currentProject = mockProjects.projects[0]
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(
            plugin.provider.workspaceState,
            .projectMissing(path: "/definitely/missing/repo")
        )
    }

    /// 当前项目目录存在 → 根布局进入 ready 状态。
    func testOnBootSetsReadyWorkspaceState() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        let project = Project(url: FileManager.default.temporaryDirectory, title: "Temp")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(plugin.provider.workspaceState, .ready)
    }

    /// 项目切换时状态同步更新，业务工作区无需先渲染一次。
    func testWorkspaceStateUpdatesOnProjectSelectionChange() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertEqual(plugin.provider.workspaceState, .noProject)

        let project = Project(url: FileManager.default.temporaryDirectory, title: "Temp")
        mockProjects.projects = [project]
        mockProjects.currentProject = project
        mockProjects.notifySelectionChanged()
        XCTAssertEqual(plugin.provider.workspaceState, .ready)

        mockProjects.currentProject = Project(
            url: URL(fileURLWithPath: "/definitely/missing/repo"),
            title: "Missing"
        )
        mockProjects.notifySelectionChanged()
        XCTAssertEqual(
            plugin.provider.workspaceState,
            .projectMissing(path: "/definitely/missing/repo")
        )
    }

    /// onShutdown 后 observer 被取消，工作区占位视图被清理。
    func testOnShutdownCancelsObserverAndResetsWorkspace() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertEqual(plugin.provider.workspaceState, .noProject)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any RootViewProviding).self).flatMap { $0 as? GitOKRootViewProvider })
    }

    /// 无 ProjectProviding 时 onBoot 不崩溃（优雅降级）。
    func testOnBootWithoutProjectProvidingDoesNotCrash() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        // 不注册 ProjectProviding。

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 即使没有 ProjectProviding，provider 替换仍然成功。
        XCTAssertTrue(kernel.resolveProvider((any RootViewProviding).self) is GitOKRootViewProvider)
    }
}
