import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderProjects
import ProviderRailView
import ProviderWorkspaceScene
import Testing
@testable import PluginWorktreeStatus

/// 覆盖 `WorktreeStatusPlugin` 的依赖守卫链，以及 Rail 区块随场景切换
/// 注入 / 撤回的行为。
@MainActor
@Suite("PluginWorktreeStatus 生命周期")
struct WorktreeStatusPluginLifecycleTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let rail: DefaultRailViewProviding
        let scene: DefaultWorkspaceSceneProvider
    }

    private func makeKernel(
        withRail: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true,
        initialScene: GitOKWorkspaceScene = .git
    ) throws -> Harness {
        let kernel = KernelCoreContainer()
        let rail = DefaultRailViewProviding()
        let scene = DefaultWorkspaceSceneProvider(initialScene: initialScene)
        if withRail {
            try kernel.registerProvider((any RailViewProviding).self, rail)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, WorktreeStatusTestsProjects())
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, DefaultGitProvider())
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        return Harness(kernel: kernel, rail: rail, scene: scene)
    }

    private var sectionID: String { "com.coffic.gitok.plugin.worktree-status.section" }

    // MARK: - 守卫链

    @Test("缺少 RailViewProviding 时不注入区块")
    func onBootWithoutRailInjectsNothing() throws {
        let harness = try makeKernel(withRail: false)
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any RailViewProviding).self) == nil)
    }

    @Test("缺少 ProjectProviding 时不注入区块")
    func onBootWithoutProjectsInjectsNothing() throws {
        let harness = try makeKernel(withProjects: false)
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.rail.sections.isEmpty)
    }

    @Test("缺少 GitProviding 时不注入区块")
    func onBootWithoutGitInjectsNothing() throws {
        let harness = try makeKernel(withGit: false)
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.rail.sections.isEmpty)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注入区块")
    func onBootWithoutSceneInjectsNothing() throws {
        let harness = try makeKernel(withScene: false)
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.rail.sections.isEmpty)
    }

    // MARK: - 区块注入与撤回

    @Test("处于 Git 场景时注入工作区状态区块")
    func onBootInjectsSectionInGitScene() throws {
        let harness = try makeKernel()
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.rail.sections.map(\.id) == [sectionID])
        #expect(harness.rail.hasVisibleSections)
    }

    @Test("处于非 Git 场景时不注入区块")
    func onBootSkipsSectionOutsideGitScene() throws {
        let harness = try makeKernel(initialScene: .banner)
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.rail.sections.isEmpty)
    }

    @Test("切换到其它场景时撤回区块")
    func sectionIsRemovedWhenSceneChanges() throws {
        let harness = try makeKernel()
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.rail.sections.count == 1)

        harness.scene.selectScene(.banner)

        #expect(harness.rail.sections.isEmpty)
    }

    @Test("切回 Git 场景时重新注入区块")
    func sectionIsReAddedWhenReturningToGitScene() throws {
        let harness = try makeKernel()
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)
        harness.scene.selectScene(.banner)
        #expect(harness.rail.sections.isEmpty)

        harness.scene.selectScene(.git)

        #expect(harness.rail.sections.map(\.id) == [sectionID])
    }

    @Test("onShutdown 撤回工作区状态区块")
    func onShutdownRemovesSection() throws {
        let harness = try makeKernel()
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.rail.sections.count == 1)

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.rail.sections.isEmpty)
    }

    @Test("onShutdown 后场景切换不再影响区块")
    func sceneChangesAfterShutdownAreIgnored() throws {
        let harness = try makeKernel()
        let plugin = WorktreeStatusPlugin()

        try plugin.onBoot(kernel: harness.kernel)
        try plugin.onShutdown(kernel: harness.kernel)

        harness.scene.selectScene(.banner)

        #expect(harness.rail.sections.isEmpty)
    }
}

// MARK: - Test Doubles

/// `ProjectProviding` 的最小替身：生命周期测试只关心依赖是否可解析。
@MainActor
final class WorktreeStatusTestsProjects: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        WorktreeStatusTestsProjectHandle()
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ file: String?) {}
    func clearCommitSelection() {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
final class WorktreeStatusTestsProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
