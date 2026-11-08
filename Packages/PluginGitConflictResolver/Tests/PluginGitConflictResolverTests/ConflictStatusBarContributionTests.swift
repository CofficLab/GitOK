import Foundation
import GitOKProviderRootView
import KernelCore
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import Testing
@testable import PluginGitConflictResolver

/// 冲突状态栏项的动态贡献：只有真的存在可渲染内容时才向 Provider 注册。
///
/// 回归背景：插件曾无条件注册一个「冲突状态」项，但视图在无进行中合并时
/// 渲染为空。`StatusBarProviding` 只在贡献列表为空时隐藏整条状态栏，
/// 于是一个渲染为空的贡献项会让窗口底部始终保留一条空的 28pt 状态栏。
@MainActor
@Suite("ConflictResolver 状态栏动态贡献")
struct ConflictStatusBarContributionTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let plugin: GitConflictResolverPlugin
        let statusBar: TestStatusBarProviding
        let projects: TestProjectsProviding
        let git: TestGitProviding
        let scene: TestSceneProviding
    }

    private func makeHarness(
        projectURL: URL?,
        isMerging: Bool
    ) throws -> Harness {
        let kernel = KernelCoreContainer()
        let statusBar = TestStatusBarProviding()
        let projects = TestProjectsProviding()
        let git = TestGitProviding()
        let scene = TestSceneProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, projects)
        try kernel.registerProvider((any GitProviding).self, git)
        try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        projects.currentProject = projectURL.map { Project(url: $0) }
        git.isMergingStub = isMerging

        let plugin = GitConflictResolverPlugin()
        try plugin.onBoot(kernel: kernel)
        return Harness(
            kernel: kernel,
            plugin: plugin,
            statusBar: statusBar,
            projects: projects,
            git: git,
            scene: scene
        )
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, !condition() {
            await Task.yield()
        }
    }

    private func settle() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }

    // MARK: - 贡献语义

    @Test("没有进行中的操作时不贡献状态栏项")
    func noItemWithoutOperation() async throws {
        let harness = try makeHarness(
            projectURL: URL(fileURLWithPath: "/tmp/conflict-idle-project"),
            isMerging: false
        )
        defer { try? harness.plugin.onShutdown(kernel: harness.kernel) }

        await settle()

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("合并开始后出现贡献项，合并结束后撤回")
    func itemFollowsOperationState() async throws {
        let url = URL(fileURLWithPath: "/tmp/conflict-transition-project")
        let harness = try makeHarness(projectURL: url, isMerging: true)
        defer { try? harness.plugin.onShutdown(kernel: harness.kernel) }

        await waitUntil { !harness.statusBar.statusBarItems.isEmpty }
        #expect(harness.statusBar.statusBarItems.map(\.id) == [GitConflictResolverPlugin.itemID])

        harness.git.isMergingStub = false
        harness.projects.send(.dataChanged)
        await waitUntil { harness.statusBar.statusBarItems.isEmpty }

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("切到非 Git 场景时撤回贡献项，回到 Git 场景后恢复")
    func itemFollowsWorkspaceScene() async throws {
        let harness = try makeHarness(
            projectURL: URL(fileURLWithPath: "/tmp/conflict-scene-project"),
            isMerging: true
        )
        defer { try? harness.plugin.onShutdown(kernel: harness.kernel) }

        await waitUntil { !harness.statusBar.statusBarItems.isEmpty }
        #expect(harness.statusBar.statusBarItems.count == 1)

        harness.scene.selectScene(.banner)
        await waitUntil { harness.statusBar.statusBarItems.isEmpty }
        #expect(harness.statusBar.statusBarItems.isEmpty)

        harness.scene.selectScene(.git)
        await waitUntil { !harness.statusBar.statusBarItems.isEmpty }
        #expect(harness.statusBar.statusBarItems.count == 1)
    }

    @Test("卸载后撤回贡献项")
    func shutdownWithdrawsItem() async throws {
        let harness = try makeHarness(
            projectURL: URL(fileURLWithPath: "/tmp/conflict-unload-project"),
            isMerging: true
        )
        await waitUntil { !harness.statusBar.statusBarItems.isEmpty }

        try harness.plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }
}
