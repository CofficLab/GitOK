import Foundation
import KernelCore
import ProviderGitRepositoryWatch
import ProviderProjectLanguages
import ProviderProjects
import Testing
@testable import PluginProjectLanguages

/// `ProjectLanguagesPlugin` 的接线覆盖。
///
/// 插件在 `onBoot` 里注册 `ProjectLanguagesProviding`，订阅项目事件
/// （选择变化 / 数据变化）与仓库监听事件（仅 refs 变化）并按需刷新；
/// `onShutdown` 取消订阅并注销 provider。
@MainActor
@Suite("ProjectLanguagesPlugin wiring")
struct ProjectLanguagesPluginWiringTests {

    // MARK: - Helpers

    /// 构造一个存在的目录（分析会失败，但足以让 `refresh` 进入 loading 状态）。
    private func makeExistingDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginProjectLanguagesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeKernel(
        withProjects: Bool = true,
        withRepositoryWatch: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        projects: LanguagesProjectsStub,
        repositoryWatch: LanguagesRepositoryWatchStub
    ) {
        let kernel = KernelCoreContainer()
        let projects = LanguagesProjectsStub()
        let repositoryWatch = LanguagesRepositoryWatchStub()
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withRepositoryWatch {
            try kernel.registerProvider((any GitRepositoryWatching).self, repositoryWatch)
        }
        return (kernel, projects, repositoryWatch)
    }

    // MARK: - 守卫

    @Test("缺少 ProjectProviding 时不注册 provider")
    func bootWithoutProjects() throws {
        let (kernel, _, _) = try makeKernel(withProjects: false)
        let plugin = ProjectLanguagesPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) == nil)
    }

    @Test("未启动就卸载是安全的")
    func shutdownWithoutBoot() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()

        try plugin.onShutdown(kernel: kernel)

        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) == nil)
    }

    // MARK: - 注册与刷新

    @Test("依赖齐备时注册 provider 并订阅项目事件")
    func bootRegistersProvider() throws {
        let (kernel, projects, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) != nil)
        #expect(projects.observerCount == 1)
    }

    @Test("当前项目已存在时启动即进入分析状态")
    func bootRefreshesCurrentProject() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        projects.currentProject = Project(url: directory)
        let plugin = ProjectLanguagesPlugin()

        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)
        #expect(provider?.isLoading == true)
    }

    @Test("没有当前项目时不进入分析状态")
    func bootWithoutCurrentProjectStaysIdle() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()

        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)
        #expect(provider?.isLoading == false)
        #expect(provider?.currentSnapshot == nil)
    }

    // MARK: - 项目事件

    @Test("项目选择变化会触发刷新")
    func selectionChangeTriggersRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)
        #expect(provider?.isLoading == false)

        projects.currentProject = Project(url: directory)
        projects.send(.selectionChanged(projectID: projects.currentProject?.id))

        #expect(provider?.isLoading == true)
    }

    @Test("项目数据变化会触发刷新")
    func dataChangeTriggersRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)

        projects.currentProject = Project(url: directory)
        projects.send(.dataChanged)

        #expect(provider?.isLoading == true)
    }

    @Test("与语言统计无关的项目事件不会触发刷新")
    func unrelatedProjectEventDoesNotRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)

        projects.currentProject = Project(url: directory)
        projects.send(.commitSelectionChanged)
        projects.send(.currentFileChanged)
        projects.send(.projectsChanged)

        #expect(provider?.isLoading == false)
    }

    // MARK: - 仓库监听事件

    @Test("注册了仓库监听时 refs 变化会触发刷新")
    func refsChangeTriggersRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)
        #expect(repositoryWatch.observerCount == 1)

        projects.currentProject = Project(url: directory)
        repositoryWatch.send(.refsChanged)

        #expect(provider?.isLoading == true)
    }

    @Test("与语言统计无关的仓库事件不会触发刷新")
    func unrelatedRepositoryEventDoesNotRefresh() throws {
        let directory = try makeExistingDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        let provider = kernel.resolveProvider((any ProjectLanguagesProviding).self)

        projects.currentProject = Project(url: directory)
        repositoryWatch.send(.headChanged(previousHead: nil, head: "abc"))
        repositoryWatch.send(.indexChanged)
        repositoryWatch.send(.stashChanged)
        repositoryWatch.send(.workingTreeChanged)

        #expect(provider?.isLoading == false)
    }

    @Test("没有注册仓库监听时也能完成接线")
    func bootWithoutRepositoryWatch() throws {
        let (kernel, _, _) = try makeKernel(withRepositoryWatch: false)
        let plugin = ProjectLanguagesPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) != nil)
    }

    // MARK: - 卸载

    @Test("onShutdown 注销 provider 并取消订阅")
    func shutdownCancelsSubscriptions() throws {
        let (kernel, projects, repositoryWatch) = try makeKernel(withRepositoryWatch: true)
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(projects.observerCount == 1)
        #expect(repositoryWatch.observerCount == 1)

        try plugin.onShutdown(kernel: kernel)

        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) == nil)
        #expect(projects.observerCount == 0)
        #expect(repositoryWatch.observerCount == 0)
    }

    // MARK: - kernel.start

    @Test("可通过 kernel.start 启动并注册 provider")
    func startViaKernel() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = ProjectLanguagesPlugin()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(kernel.resolveProvider((any ProjectLanguagesProviding).self) != nil)
        try kernel.stop()
    }
}
