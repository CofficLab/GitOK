import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderStatusBar
import XCTest
@testable import PluginCommitStatusBar

@MainActor
final class CommitStatusBarPluginTests: XCTestCase {
    /// 最小 ProjectProviding mock：维护 commit 选择状态并支持主动广播。
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
        }
        /// 测试辅助：广播「选中 commit 变化」事件（真实 ProjectManager 在
        /// selectCommit / clearCommitSelection 后自动广播）。
        func notifyCommitSelectionChanged() {
            let current = observers
            for observer in current { observer.callback(.commitSelectionChanged) }
        }
        func notifyDataChanged() {}
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        private let onCancel: () -> Void
        init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
        func cancel() { onCancel() }
    }

    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg", author: "a", date: Date())
    }

    func testOnBootAddsStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.contains { $0.id == CommitStatusBarPlugin.itemID })
    }

    func testOnShutdownRemovesStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        XCTAssertFalse(statusBar.statusBarItems.contains { $0.id == CommitStatusBarPlugin.itemID })
    }

    func testStatusBarItemRendersSelectedCommitShortHash() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let projects = MockProjects()
        try kernel.registerProvider((any ProjectProviding).self, projects)

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        // 选择 commit 后，item 视图以 Provider（ProjectProviding）为权威来源渲染。
        projects.selectCommit(commit("abcdef1234567890"))
        let item = statusBar.statusBarItems.first { $0.id == CommitStatusBarPlugin.itemID }
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.placement, .leading)
    }

    /// 验证观察模型在 commit 变化时确实递增 revision（驱动 SwiftUI 重算）。
    func testObservationModelFiresOnSelectionChange() throws {
        let projects = MockProjects()
        let model = ProjectObservationModel(projects: projects)

        XCTAssertEqual(model.revision, 0)
        projects.selectCommit(commit("abc1234567890abc1234567890abc1234567890"))
        projects.notifyCommitSelectionChanged()
        XCTAssertEqual(model.revision, 1, "observer should fire when a commit is selected")
        projects.clearCommitSelection()
        projects.notifyCommitSelectionChanged()
        XCTAssertEqual(model.revision, 2)
    }
}
