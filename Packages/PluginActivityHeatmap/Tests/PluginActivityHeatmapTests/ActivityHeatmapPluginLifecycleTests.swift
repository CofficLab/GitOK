import Foundation
import KernelCore
import KitGit
import ProviderActivityHeatmap
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderStorage
import Testing
@testable import PluginActivityHeatmap

/// `ActivityHeatmapPlugin` 的生命周期接线覆盖。
///
/// 插件在 `onBoot` 里注册 `ActivityHeatmapProviding`（底层是本地 Git 提交
/// 活跃度统计），并订阅项目选择变化与仓库 refs 变化触发刷新；
/// `onShutdown` 取消订阅并注销 provider。
@MainActor
@Suite("ActivityHeatmapPlugin lifecycle")
struct ActivityHeatmapPluginLifecycleTests {

    // MARK: - Test doubles

    /// `ProjectProviding` 的可控替身。
    @MainActor
    final class ProjectsStub: ProjectProviding {
        var projects: [Project] = []
        var currentProject: Project?
        var currentCommit: GitCommit?
        var currentFile: String?
        var currentCommitFiles: [GitFileChange]?
        var isLoadingCommitFiles = false
        var currentCommitFilesLoadError: String?

        private var observers: [UUID: (ProjectProvidingEvent) -> Void] = [:]
        private(set) var observerCount = 0

        func addObserver(
            _ callback: @escaping (ProjectProvidingEvent) -> Void
        ) -> any ProjectProvidingObserverHandle {
            let id = UUID()
            observers[id] = callback
            observerCount += 1
            return Handle { [weak self] in
                self?.observers.removeValue(forKey: id)
                self?.observerCount -= 1
            }
        }

        func send(_ event: ProjectProvidingEvent) {
            for callback in observers.values { callback(event) }
        }

        func openProject(at url: URL) { currentProject = Project(url: url) }
        func closeCurrentProject() { currentProject = nil }
        func addProject(at url: URL) { projects.append(Project(url: url)) }
        func removeProject(id: UUID) { projects.removeAll { $0.id == id } }
        func renameProject(id: UUID, newName: String) throws {}
        func pinProject(id: UUID, isPinned: Bool) {}
        func moveProject(id: UUID, beforeID: UUID?) {}
        func selectCommit(_ commit: GitCommit) { currentCommit = commit }
        func selectFile(_ file: String?) { currentFile = file }
        func clearCommitSelection() {
            currentCommit = nil
            currentFile = nil
        }
        func setCurrentProject(id: UUID?) {}
        func refresh() {}
        func notifyDataChanged() {}
        func persist() {}
    }

    @MainActor
    final class Handle: ProjectProvidingObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() { onCancel() }
    }

    /// `GitRepositoryWatching` 的可控替身。
    @MainActor
    final class RepositoryWatchStub: GitRepositoryWatching {
        private(set) var watchingRepositoryURL: URL?
        private var observers: [UUID: (GitRepositoryWatchingEvent) -> Void] = [:]
        private(set) var observerCount = 0

        func addObserver(
            _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
        ) -> any GitRepositoryWatchingObserverHandle {
            let id = UUID()
            observers[id] = callback
            observerCount += 1
            return RepositoryHandle { [weak self] in
                self?.observers.removeValue(forKey: id)
                self?.observerCount -= 1
            }
        }

        func startWatching(repositoryURL: URL) { watchingRepositoryURL = repositoryURL }
        func stopWatching() { watchingRepositoryURL = nil }

        func send(_ event: GitRepositoryWatchingEvent) {
            for callback in observers.values { callback(event) }
        }
    }

    @MainActor
    final class RepositoryHandle: GitRepositoryWatchingObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() { onCancel() }
    }

    // MARK: - Helpers

    private func makeKernel(
        withGit: Bool = true,
        withProjects: Bool = true,
        withStorage: Bool = true,
        withRepositoryWatch: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        projects: ProjectsStub,
        repositoryWatch: RepositoryWatchStub
    ) {
        let kernel = KernelCoreContainer()
        let projects = ProjectsStub()
        let repositoryWatch = RepositoryWatchStub()
        if withGit {
            try kernel.registerProvider((any GitProviding).self, DefaultGitProvider())
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withStorage {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("ActivityHeatmapStorage-\(UUID().uuidString)", isDirectory: true)
            try kernel.registerProvider(
                (any StorageProviding).self,
                DefaultStorageProvider(dataRootDirectory: root)
            )
        }
        if withRepositoryWatch {
            try kernel.registerProvider((any GitRepositoryWatching).self, repositoryWatch)
        }
        return (kernel, projects, repositoryWatch)
    }

    private func makeExistingDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ActivityHeatmapRepo-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - 守卫链

    @Test("缺少 Git 提供方时不注册 provider")
    func bootWithoutGit() throws {
        let (kernel, _, _) = try makeKernel(withGit: false)
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) == nil)
    }

    @Test("缺少项目提供方时不注册 provider")
    func bootWithoutProjects() throws {
        let (kernel, _, _) = try makeKernel(withProjects: false)
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) == nil)
    }

    @Test("缺少存储提供方时不注册 provider")
    func bootWithoutStorage() throws {
        let (kernel, _, _) = try makeKernel(withStorage: false)
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) == nil)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) == nil)
    }

    // MARK: - 注册与刷新

    @Test("依赖齐备时注册 provider 并订阅项目事件")
    func bootRegistersProvider() throws {
        let (kernel, projects, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) != nil)
        #expect(projects.observerCount == 1)
    }

    @Test("当前项目已存在时启动即进入加载状态")
    func bootRefreshesCurrentProject() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        projects.currentProject = Project(url: directory)
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)
        #expect(provider?.isLoading == true)
    }

    @Test("没有当前项目时不进入加载状态")
    func bootWithoutCurrentProjectStaysIdle() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()

        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)
        #expect(provider?.isLoading == false)
        #expect(provider?.currentSnapshot == nil)
    }

    // MARK: - 项目事件

    @Test("项目选择变化会触发刷新")
    func selectionChangeTriggersRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)
        #expect(provider?.isLoading == false)

        projects.currentProject = Project(url: directory)
        projects.send(.selectionChanged(projectID: projects.currentProject?.id))

        #expect(provider?.isLoading == true)
    }

    @Test("与活跃度统计无关的项目事件不会触发刷新")
    func unrelatedProjectEventDoesNotRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)

        projects.currentProject = Project(url: directory)
        projects.send(.dataChanged)
        projects.send(.commitSelectionChanged)
        projects.send(.projectsChanged)

        #expect(provider?.isLoading == false)
    }

    // MARK: - 仓库监听事件

    @Test("注册了仓库监听时 refs 变化会触发刷新")
    func refsChangeTriggersRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)
        #expect(repositoryWatch.observerCount == 1)

        projects.currentProject = Project(url: directory)
        repositoryWatch.send(.refsChanged)

        #expect(provider?.isLoading == true)
    }

    @Test("与活跃度统计无关的仓库事件不会触发刷新")
    func unrelatedRepositoryEventDoesNotRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ActivityHeatmapProviding).self)

        projects.currentProject = Project(url: directory)
        repositoryWatch.send(.headChanged(previousHead: nil, head: "abc"))
        repositoryWatch.send(.indexChanged)
        repositoryWatch.send(.workingTreeChanged)

        #expect(provider?.isLoading == false)
    }

    // MARK: - 卸载

    @Test("onShutdown 注销 provider 并取消订阅")
    func shutdownCancelsSubscriptions() throws {
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ActivityHeatmapPlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(projects.observerCount == 1)
        #expect(repositoryWatch.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)

        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) == nil)
        #expect(projects.observerCount == 0)
        #expect(repositoryWatch.observerCount == 0)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并注册 provider")
    func startViaKernel() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ActivityHeatmapPlugin()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(kernel.resolveProvider((any ActivityHeatmapProviding).self) != nil)
        try kernel.stop()
    }
}
