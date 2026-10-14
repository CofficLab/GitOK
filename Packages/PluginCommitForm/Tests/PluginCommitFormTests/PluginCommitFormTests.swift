import Foundation
import KernelCore
import KitGit
import ProviderCommitForm
import ProviderContentView
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderWorkspaceScene
import Testing
@testable import PluginCommitForm
@testable import ProviderContentView

@Suite("PluginCommitForm")
@MainActor
struct PluginCommitFormTests {

    /// 最小 ProjectProviding mock：空项目列表。
    private final class MockProjects: ProjectProviding {
        var projects: [Project] = []
        var currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?
        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle { MockHandle() }
        func openProject(at url: URL) {}
        func closeCurrentProject() {}
        func addProject(at url: URL) {}
        func removeProject(id: UUID) {}
        func renameProject(id: UUID, newName: String) throws {}
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
        func notifyDataChanged() {}
    }

    private final class MockHandle: ProjectProvidingObserverHandle {
        func cancel() {}
    }

    private func makeKernel() throws -> (
        kernel: KernelCoreContainer,
        contentView: DefaultContentViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        try kernel.registerProvider((any CommitFormProviding).self, DefaultCommitFormProvider())
        try kernel.registerProvider((any GitProviding).self, DefaultGitProvider())
        try kernel.registerProvider(
            (any WorkspaceSceneProviding).self,
            DefaultWorkspaceSceneProvider()
        )
        return (kernel, contentView)
    }

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = CommitFormPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.commit-form")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .required)
    }

    /// 记录内容块变更次数：注册内容块会广播 `.contentChanged`，未注册则不广播。
    private func observeContentChanges(
        _ contentView: DefaultContentViewProviding
    ) -> (handle: any ContentViewObserverHandle, count: () -> Int) {
        final class Counter: @unchecked Sendable {
            var value = 0
        }
        let counter = Counter()
        let handle = contentView.addContentViewObserver { _ in counter.value += 1 }
        return (handle, { counter.value })
    }

    @Test("onBoot 贡献表单内容块，onShutdown 移除")
    func contentContributionLifecycle() throws {
        let (kernel, contentView) = try makeKernel()
        let (handle, changeCount) = observeContentChanges(contentView)
        let plugin = CommitFormPlugin()
        try plugin.onBoot(kernel: kernel)

        // onBoot 应通过 addContentView 注入内容块。
        let changesAfterBoot = changeCount()
        #expect(changesAfterBoot >= 1)

        try plugin.onShutdown(kernel: kernel)
        // removeContentView 仅在确实移除了内容块时才广播事件，
        // 事件数增加即证明 onShutdown 按插件内容 id 清掉了注册内容。
        #expect(changeCount() > changesAfterBoot)
        handle.cancel()
    }

    @Test("onBoot 缺少 ContentViewProviding 时跳过内容贡献，不抛错")
    func onBootSkipsContentWhenMissingProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any ProjectProviding).self, MockProjects())
        try kernel.registerProvider((any CommitFormProviding).self, DefaultCommitFormProvider())

        try CommitFormPlugin().onBoot(kernel: kernel)
    }

    @Test("GitRepositoryWatchObservationModel 订阅仓库监听事件并递增 revision")
    func gitWatchObservationForwardsEvents() {
        let watch = DefaultGitRepositoryWatching()
        let model = GitRepositoryWatchObservationModel(gitWatch: watch)

        let before = model.revision
        watch.broadcast(.headChanged(previousHead: "a", head: "b"))
        watch.broadcast(.workingTreeChanged)
        #expect(model.revision == before + 2)
    }

    @Test("GitRepositoryWatchObservationModel 无监听时保持静止")
    func gitWatchObservationNoOpWithoutWatcher() {
        let model = GitRepositoryWatchObservationModel(gitWatch: nil)
        #expect(model.revision == 0)
    }

    @Test("CommitFormErrorCenter presents and dismisses errors")
    func errorCenterPresentDismiss() {
        let center = CommitFormErrorCenter()
        #expect(center.error == nil)

        center.present(operation: "commit", message: "boom")
        #expect(center.error?.operation == "commit")
        #expect(center.error?.message == "boom")

        center.dismiss()
        #expect(center.error == nil)
    }

    @Test("CommitFormErrorCenter overwrites previous error on present")
    func errorCenterOverwrites() {
        let center = CommitFormErrorCenter()
        center.present(operation: "first", message: "one")
        center.present(operation: "second", message: "two")
        #expect(center.error?.operation == "second")
        #expect(center.error?.message == "two")
    }
}
