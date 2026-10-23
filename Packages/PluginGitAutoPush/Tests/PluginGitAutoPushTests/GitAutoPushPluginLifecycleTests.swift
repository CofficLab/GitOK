import Foundation
import KernelCore
import KitGit
import ProviderAutoPush
import ProviderCommitForm
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import ProviderStorage
import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import PluginGitAutoPush

/// 覆盖 `GitAutoPushPlugin` 的依赖守卫链、状态栏项注入，以及
/// 「提交成功后自动推送」这一核心行为。
@MainActor
@Suite("PluginGitAutoPush 生命周期")
struct GitAutoPushPluginLifecycleTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let git: AutoPushTestGit
        let projects: AutoPushTestProjects
        let commitForm: AutoPushTestCommitForm
        let statusBar: DefaultStatusBarProviding
        let scene: DefaultWorkspaceSceneProvider
        let projectURL: URL
        let root: URL
    }

    private func makeHarness(
        withStatusBar: Bool = true,
        withProjects: Bool = true,
        withGit: Bool = true,
        withScene: Bool = true,
        withStorage: Bool = true,
        withCommitForm: Bool = true
    ) throws -> Harness {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKAutoPushTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let kernel = KernelCoreContainer()
        let git = AutoPushTestGit()
        let projects = AutoPushTestProjects()
        let commitForm = AutoPushTestCommitForm()
        let statusBar = DefaultStatusBarProviding()
        let scene = DefaultWorkspaceSceneProvider()
        let projectURL = root.appendingPathComponent("project", isDirectory: true)

        projects.currentProject = Project(id: UUID(), url: projectURL, title: "project")

        if withStatusBar {
            try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, git)
        }
        if withScene {
            try kernel.registerProvider((any WorkspaceSceneProviding).self, scene)
        }
        if withStorage {
            try kernel.registerProvider(
                (any StorageProviding).self,
                AutoPushTestStorage(dataRootDirectory: root)
            )
        }
        if withCommitForm {
            try kernel.registerProvider((any CommitFormProviding).self, commitForm)
        }

        return Harness(
            kernel: kernel,
            git: git,
            projects: projects,
            commitForm: commitForm,
            statusBar: statusBar,
            scene: scene,
            projectURL: projectURL,
            root: root
        )
    }

    private func cleanUp(_ harness: Harness) {
        try? FileManager.default.removeItem(at: harness.root)
    }

    // MARK: - 守卫链

    @Test("缺少 StatusBarProviding 时不注入状态栏项")
    func onBootWithoutStatusBarInjectsNothing() throws {
        let harness = try makeHarness(withStatusBar: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少 ProjectProviding 时不注入状态栏项")
    func onBootWithoutProjectsInjectsNothing() throws {
        let harness = try makeHarness(withProjects: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 GitProviding 时不注入状态栏项")
    func onBootWithoutGitInjectsNothing() throws {
        let harness = try makeHarness(withGit: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 WorkspaceSceneProviding 时不注入状态栏项")
    func onBootWithoutSceneInjectsNothing() throws {
        let harness = try makeHarness(withScene: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 StorageProviding 时不注入状态栏项")
    func onBootWithoutStorageInjectsNothing() throws {
        let harness = try makeHarness(withStorage: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    @Test("缺少 CommitFormProviding 时仍注入状态栏项")
    func onBootWithoutCommitFormStillInjectsItem() throws {
        let harness = try makeHarness(withCommitForm: false)
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.count == 1)
    }

    // MARK: - 注入与撤回

    @Test("依赖齐备时注入 leading 状态栏项并注册 AutoPushProviding")
    func onBootInjectsItemAndRegistersProvider() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.count == 1)
        let item = harness.statusBar.statusBarItems.first
        #expect(item?.id == GitAutoPushPlugin.itemID)
        #expect(item?.placement == .leading)
        #expect(item?.order == 21)
        #expect(harness.kernel.isProviderRegistered((any AutoPushProviding).self))
    }

    @Test("onShutdown 撤回状态栏项")
    func onShutdownRemovesStatusBarItem() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 自动推送

    @Test("启用自动推送的项目在提交成功后自动推送")
    func committedEventTriggersAutoPush() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        let autoPush = harness.kernel.resolveProvider((any AutoPushProviding).self)
        autoPush?.setEnabled(true, for: harness.projectURL)
        #expect(autoPush?.isEnabled(for: harness.projectURL) == true)

        harness.commitForm.emitCommitted()

        let pushed = await waitUntil { harness.git.pushCount == 1 }
        #expect(pushed, "提交成功后应自动推送")
        #expect(harness.git.pushedRepositories == [harness.projectURL.path])
    }

    @Test("未启用自动推送的项目在提交成功后不推送")
    func committedEventDoesNotPushWhenDisabled() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        harness.commitForm.emitCommitted()

        // 给自动推送的异步执行留出时间，确认它确实没有发生。
        try? await Task.sleep(for: .milliseconds(200))
        #expect(harness.git.pushCount == 0)
    }

    @Test("没有当前项目时提交成功不触发推送")
    func committedEventWithoutCurrentProjectDoesNotPush() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        let autoPush = harness.kernel.resolveProvider((any AutoPushProviding).self)
        autoPush?.setEnabled(true, for: harness.projectURL)
        harness.projects.currentProject = nil

        harness.commitForm.emitCommitted()

        try? await Task.sleep(for: .milliseconds(200))
        #expect(harness.git.pushCount == 0)
    }

    @Test("仓库没有当前分支时提交成功不推送")
    func committedEventWithoutBranchDoesNotPush() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = GitAutoPushPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        let autoPush = harness.kernel.resolveProvider((any AutoPushProviding).self)
        autoPush?.setEnabled(true, for: harness.projectURL)
        harness.git.currentBranchName = nil

        harness.commitForm.emitCommitted()

        try? await Task.sleep(for: .milliseconds(200))
        #expect(harness.git.pushCount == 0)
    }

    // MARK: - Helpers

    /// 自动推送在后台线程执行，这里轮询等待它落到 Git 后端上。
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }
}
