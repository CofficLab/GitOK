import Foundation
import KernelCore
import KitGit
import ProviderProjects
import ProviderToast
import XCTest
@testable import PluginCommitToast

@MainActor
final class CommitToastPluginTests: XCTestCase {
    /// 测试用 toast 记录器。
    private final class RecordingToastProvider: ToastProviding {
        var received: [LumiToast] = []
        func show(_ toast: LumiToast) {
            received.append(toast)
        }
    }

    /// 最小 ProjectProviding mock：维护 commit 选择状态，可主动广播
    /// `commitSelectionChanged`（模拟真实 ProjectManager 的选择广播）。
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
        /// 模拟真实 ProjectManager：同 hash 去重 + 选择变化即广播。
        func selectCommit(_ commit: GitCommit) {
            guard currentCommit?.hash != commit.hash else { return }
            currentCommit = commit
            currentFile = nil
            notifyCommitSelectionChanged()
        }
        func selectFile(_ path: String?) { currentFile = path }
        func clearCommitSelection() {
            guard currentCommit != nil || currentFile != nil else { return }
            currentCommit = nil
            currentFile = nil
            currentCommitFiles = nil
            notifyCommitSelectionChanged()
        }
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
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg \(hash)", author: "a", date: Date())
    }

    func testSelectCommitFiresToast() throws {
        let kernel = KernelCoreContainer()
        let projects = MockProjects()
        try kernel.registerProvider((any ProjectProviding).self, projects)
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        projects.selectCommit(commit("abc"))

        XCTAssertEqual(toast.received.count, 1)
        XCTAssertEqual(toast.received[0].style, .info)
    }

    func testSameCommitSelectionDoesNotReToast() throws {
        let kernel = KernelCoreContainer()
        let projects = MockProjects()
        try kernel.registerProvider((any ProjectProviding).self, projects)
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        projects.selectCommit(commit("abc"))
        projects.selectCommit(commit("abc")) // 相同选择：Provider 去重，不重复通知

        XCTAssertEqual(toast.received.count, 1)
    }

    func testClearSelectionFiresToast() throws {
        let kernel = KernelCoreContainer()
        let projects = MockProjects()
        try kernel.registerProvider((any ProjectProviding).self, projects)
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        projects.selectCommit(commit("abc"))
        projects.clearCommitSelection()

        XCTAssertEqual(toast.received.count, 2)
        XCTAssertNil(projects.currentCommit)
    }

    func testOnShutdownCancelsSubscription() throws {
        let kernel = KernelCoreContainer()
        let projects = MockProjects()
        try kernel.registerProvider((any ProjectProviding).self, projects)
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        projects.selectCommit(commit("abc"))

        XCTAssertTrue(toast.received.isEmpty, "after shutdown no commit-change toast should fire")
    }
}
