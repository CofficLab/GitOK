import Foundation
import KernelCore
import KitGit
import ProviderCommitForm
import ProviderContentView
import ProviderGitRepositoryWatch
import ProviderProjects
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
        return (kernel, contentView)
    }

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = CommitFormPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.commit-form")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .required)
    }

    @Test("onBoot 贡献表单内容块，onShutdown 移除")
    func contentContributionLifecycle() throws {
        let (kernel, contentView) = try makeKernel()
        let plugin = CommitFormPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(contentView.registeredIDs.contains("com.coffic.gitok.plugin.commit-form.content"))

        try plugin.onShutdown(kernel: kernel)
        #expect(!contentView.registeredIDs.contains("com.coffic.gitok.plugin.commit-form.content"))
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
}
