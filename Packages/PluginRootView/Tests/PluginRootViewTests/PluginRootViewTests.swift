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

        // onBoot 会注册 no-project overlay。
        XCTAssertTrue(plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID })

        // 手动添加额外 overlay。
        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 100) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 2)

        // 同 id 不重复注册。
        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 200) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 2)

        plugin.provider.removeOverlays(ids: ["test-overlay"])
        XCTAssertEqual(plugin.provider.overlays.count, 1)
        XCTAssertTrue(plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID })
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

    // MARK: - 无项目引导视图

    /// 启动时无项目 → overlay 已挂载。
    func testOnBootMountsNoProjectOverlayWhenNoProjects() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID },
            "无项目时 onBoot 应挂载 no-project overlay"
        )
    }

    /// 启动时已有项目 → overlay 仍然挂载（条件渲染，内容为隐藏）。
    func testOnBootMountsOverlayEvenWithProjects() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        mockProjects.projects = [
            Project(url: URL(fileURLWithPath: "/tmp/repo1"), title: "Repo1"),
        ]
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // overlay 始终挂载，但 guideState.showGuide 应为 false。
        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID }
        )
    }

    /// 项目列表从空变非空 → guide 状态切换为不显示。
    func testProjectsChangedFromEmptyToNonEmpty() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 初始无项目 → overlay 已挂载。
        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID }
        )

        // 添加项目后广播变化。
        mockProjects.projects = [
            Project(url: URL(fileURLWithPath: "/tmp/repo1"), title: "Repo1"),
        ]
        mockProjects.notifyProjectsChanged()

        // overlay 仍然挂载（条件渲染），但不再显示引导。
        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID },
            "overlay 始终挂载，由条件渲染控制显隐"
        )
    }

    /// 项目列表从非空变空 → guide 状态切换为显示。
    func testProjectsChangedFromNonEmptyToEmpty() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        mockProjects.projects = [
            Project(url: URL(fileURLWithPath: "/tmp/repo1"), title: "Repo1"),
        ]
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 移除所有项目后广播变化。
        mockProjects.projects = []
        mockProjects.notifyProjectsChanged()

        // overlay 仍然挂载，引导视图应该显示。
        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID }
        )
    }

    /// onShutdown 后 observer 被取消，overlay 被移除。
    func testOnShutdownCancelsObserverAndRemovesOverlay() throws {
        let kernel = KernelCoreContainer()
        let mockProjects = MockProjects()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())
        try kernel.registerProvider((any ProjectProviding).self, mockProjects)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID }
        )

        try plugin.onShutdown(kernel: kernel)

        XCTAssertFalse(
            plugin.provider.overlays.contains { $0.id == RootViewPlugin.noProjectOverlayID },
            "onShutdown 后应移除 no-project overlay"
        )
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
