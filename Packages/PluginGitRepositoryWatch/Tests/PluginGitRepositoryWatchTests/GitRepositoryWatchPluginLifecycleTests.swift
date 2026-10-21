import Foundation
import KernelCore
import ProviderDocsView
import ProviderGitRepositoryWatch
import ProviderProjects
import XCTest
@testable import PluginGitRepositoryWatch

/// `GitRepositoryWatchPlugin` 的生命周期接线覆盖。
///
/// 插件把 `GitRepositoryWatchProvider` 注册到内核，并订阅 `ProjectProviding`
/// 的选择事件把监听目标同步到当前项目；`onRegister` / `onUnregister` 负责
/// 「关于」条目的挂载与撤回。
@MainActor
final class GitRepositoryWatchPluginLifecycleTests: XCTestCase {

    // MARK: - Helpers

    private func makeSyntheticRepository() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-watch-lifecycle-\(UUID().uuidString)")
        let gitDir = root.appendingPathComponent(".git")
        try FileManager.default.createDirectory(
            at: gitDir.appendingPathComponent("refs/heads"),
            withIntermediateDirectories: true
        )
        try "ref: refs/heads/main\n".write(
            to: gitDir.appendingPathComponent("HEAD"),
            atomically: true,
            encoding: .utf8
        )
        return root
    }

    private func makeKernel(
        withProjects: Bool = true,
        withDocs: Bool = false
    ) throws -> (kernel: KernelCoreContainer, projects: WatchProjectsStub, docs: DefaultDocsViewProviding) {
        let kernel = KernelCoreContainer()
        let projects = WatchProjectsStub()
        let docs = DefaultDocsViewProviding()
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, projects, docs)
    }

    // MARK: - onBoot

    func testOnBootWithoutProjectsSkipsProviderRegistration() throws {
        let (kernel, _, _) = try makeKernel(withProjects: false)
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onBoot(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any GitRepositoryWatching).self))
    }

    func testOnBootRegistersWatchingProvider() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let provider = kernel.resolveProvider((any GitRepositoryWatching).self)
        XCTAssertNotNil(provider, "onBoot 应把 GitRepositoryWatchProvider 注册到内核")
        XCTAssertTrue(provider is GitRepositoryWatchProvider)
    }

    func testOnBootStartsWatchingCurrentProject() throws {
        let repo = try makeSyntheticRepository()
        defer { try? FileManager.default.removeItem(at: repo) }
        let (kernel, projects, _) = try makeKernel()
        projects.currentProject = Project(url: repo)
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let provider = kernel.resolveProvider((any GitRepositoryWatching).self)
        XCTAssertEqual(provider?.watchingRepositoryURL, repo.standardizedFileURL)
        let concreteProvider = provider as? GitRepositoryWatchProvider
        XCTAssertEqual(concreteProvider?.isWatcherActive, true)
        XCTAssertNotNil(concreteProvider?.watchedGitDirectoryPath)
    }

    func testProjectSelectionChangeSyncsWatchTarget() throws {
        let first = try makeSyntheticRepository()
        let second = try makeSyntheticRepository()
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let (kernel, projects, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }
        let provider = kernel.resolveProvider((any GitRepositoryWatching).self)

        // 切换到第一个项目 → 开始监听。
        projects.currentProject = Project(url: first)
        projects.send(.selectionChanged(projectID: projects.currentProject?.id))
        XCTAssertEqual(provider?.watchingRepositoryURL, first.standardizedFileURL)

        // 切换到第二个项目 → 停止旧监听并切到新项目。
        projects.currentProject = Project(url: second)
        projects.send(.selectionChanged(projectID: projects.currentProject?.id))
        XCTAssertEqual(provider?.watchingRepositoryURL, second.standardizedFileURL)

        // 关闭项目 → 停止监听。
        projects.currentProject = nil
        projects.send(.selectionChanged(projectID: nil))
        XCTAssertNil(provider?.watchingRepositoryURL)
    }

    func testOnBootSubscribesToProjectEvents() throws {
        let (kernel, projects, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        XCTAssertEqual(projects.observerCount, 1, "onBoot 应订阅项目变化")
    }

    // MARK: - onShutdown

    func testOnShutdownUnregistersProviderAndCancelsSubscription() throws {
        let (kernel, projects, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any GitRepositoryWatching).self))
        XCTAssertEqual(projects.observerCount, 0, "onShutdown 应取消项目订阅")
    }

    func testOnShutdownStopsWatching() throws {
        let repo = try makeSyntheticRepository()
        defer { try? FileManager.default.removeItem(at: repo) }
        let (kernel, projects, _) = try makeKernel()
        projects.currentProject = Project(url: repo)
        let plugin = GitRepositoryWatchPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any GitRepositoryWatching).self))
    }

    func testOnShutdownWithoutBootIsSafe() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onShutdown(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any GitRepositoryWatching).self))
    }

    // MARK: - kernel.start

    func testStartViaKernelRegistersPluginAndProvider() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()

        try kernel.start(plugins: [plugin])

        XCTAssertTrue(kernel.isPluginRegistered(id: plugin.id))
        XCTAssertNotNil(kernel.resolveProvider((any GitRepositoryWatching).self))
        try kernel.stop()
    }

    func testStopViaKernelTearsDownProvider() throws {
        let (kernel, _, _) = try makeKernel()
        let plugin = GitRepositoryWatchPlugin()
        try kernel.start(plugins: [plugin])
        XCTAssertNotNil(kernel.resolveProvider((any GitRepositoryWatching).self))

        try kernel.stop()

        XCTAssertNil(kernel.resolveProvider((any GitRepositoryWatching).self))
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterAddsAboutEntryAndOnUnregisterRemovesIt() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onRegister(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testOnRegisterWithoutDocsProviderIsSafe() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = GitRepositoryWatchPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - Metadata

    func testPluginMetadata() {
        let plugin = GitRepositoryWatchPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.git-repository-watch")
        XCTAssertEqual(plugin.order, 5)
        XCTAssertEqual(plugin.metadata.category, .project)
        XCTAssertEqual(plugin.metadata.policy, .required)
    }
}
