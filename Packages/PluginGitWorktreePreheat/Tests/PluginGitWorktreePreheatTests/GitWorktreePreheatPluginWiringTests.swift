import Foundation
import KernelCore
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import Testing
@testable import PluginGitWorktreePreheat

// MARK: - Test doubles

/// 线程安全的预热记录器。
final class PreheatLoadRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [URL] = []
    private var invalidated: [URL] = []

    func append(_ url: URL) {
        lock.lock(); defer { lock.unlock() }
        values.append(url)
    }

    func invalidate(_ url: URL) {
        lock.lock(); defer { lock.unlock() }
        invalidated.append(url)
    }

    var urls: [URL] {
        lock.lock(); defer { lock.unlock() }
        return values
    }

    var invalidatedURLs: [URL] {
        lock.lock(); defer { lock.unlock() }
        return invalidated
    }
}

// MARK: - Tests

/// `GitWorktreePreheatPlugin` 的生命周期接线覆盖。
@Suite("GitWorktreePreheatPlugin 接线")
@MainActor
struct GitWorktreePreheatPluginWiringTests {

    private func makeKernel(
        withProjects: Bool = true,
        withGit: Bool = true,
        withGitWatch: Bool = true
    ) throws -> (
        kernel: KernelCoreContainer,
        projects: EventProjects,
        git: WorktreePreheatDoubles.Git,
        gitWatch: EventGitWatch
    ) {
        let kernel = KernelCoreContainer()
        let projects = EventProjects()
        let git = WorktreePreheatDoubles.Git()
        let gitWatch = EventGitWatch()
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, projects)
        }
        if withGit {
            try kernel.registerProvider((any GitProviding).self, git)
        }
        if withGitWatch {
            try kernel.registerProvider((any GitRepositoryWatching).self, gitWatch)
        }
        return (kernel, projects, git, gitWatch)
    }

    @Test("插件元数据符合预热插件规范")
    func pluginMetadata() {
        let plugin = GitWorktreePreheatPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-worktree-preheat")
        #expect(plugin.order == 10)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.metadata.policy == .required)
    }

    @Test("缺少项目提供方时不订阅任何事件")
    func bootWithoutProjects() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel(withProjects: false)
        let plugin = GitWorktreePreheatPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(projects.observerCount == 0)
        #expect(gitWatch.observerCount == 0)
    }

    @Test("缺少 Git 提供方时不订阅任何事件")
    func bootWithoutGit() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel(withGit: false)
        let plugin = GitWorktreePreheatPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(projects.observerCount == 0)
        #expect(gitWatch.observerCount == 0)
    }

    @Test("依赖齐备时订阅项目事件与仓库监听事件")
    func bootSubscribesProjectsAndGitWatch() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel()
        let plugin = GitWorktreePreheatPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(projects.observerCount == 1)
        #expect(gitWatch.observerCount == 1)
    }

    @Test("没有仓库监听提供方时只订阅项目事件")
    func bootWithoutGitWatch() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel(withGitWatch: false)
        let plugin = GitWorktreePreheatPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(projects.observerCount == 1)
        #expect(gitWatch.observerCount == 0)
    }

    @Test("启动后会把项目目录交给 Git 加载工作区快照")
    func bootLoadsSnapshotForProject() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let (kernel, projects, git, _) = try makeKernel()
        projects.projects = [Project(url: project)]
        projects.currentProject = Project(url: project)
        let plugin = GitWorktreePreheatPlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        for _ in 0..<100 where git.loadWorktreeSnapshotCount == 0 {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(git.loadWorktreeSnapshotCount >= 1)
    }

    @Test("仓库监听启动事件会让插件作废对应仓库的快照缓存")
    func gitWatchStartedInvalidatesSnapshot() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let (kernel, projects, git, gitWatch) = try makeKernel()
        projects.projects = [Project(url: project)]
        let plugin = GitWorktreePreheatPlugin()
        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        gitWatch.send(.started(repositoryURL: project))

        for _ in 0..<100 where git.invalidateWorktreeSnapshotCount == 0 {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(git.invalidateWorktreeSnapshotCount >= 1)
    }

    @Test("onShutdown 取消项目与仓库监听订阅")
    func shutdownCancelsSubscriptions() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel()
        let plugin = GitWorktreePreheatPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        #expect(projects.observerCount == 0)
        #expect(gitWatch.observerCount == 0)
    }

    @Test("onRegister / onUnregister 是空操作")
    func registerAndUnregisterAreNoops() throws {
        let (kernel, _, _, _) = try makeKernel()
        let plugin = GitWorktreePreheatPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("可通过 kernel.start 启动并订阅事件")
    func startViaKernel() throws {
        let (kernel, projects, _, gitWatch) = try makeKernel()
        let plugin = GitWorktreePreheatPlugin()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(projects.observerCount == 1)
        #expect(gitWatch.observerCount == 1)
        try kernel.stop()
    }
}

/// `WorktreeSnapshotPreheater` 的事件响应覆盖。
@Suite("WorktreeSnapshotPreheater 事件响应")
@MainActor
struct WorktreeSnapshotPreheaterEventTests {

    private func makePreheater(
        projects: EventProjects,
        gitWatch: EventGitWatch?,
        recorder: PreheatLoadRecorder
    ) -> WorktreeSnapshotPreheater {
        WorktreeSnapshotPreheater(
            projects: projects,
            loadSnapshot: { url, _ in recorder.append(url) },
            invalidateSnapshot: { url in recorder.invalidate(url) },
            gitWatch: gitWatch
        )
    }

    private func waitFor(_ predicate: @escaping () -> Bool) async {
        for _ in 0..<100 where !predicate() {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    @Test("项目列表变化会重新排队预热")
    func projectsChangedTriggersRefresh() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: project)]
        projects.currentProject = Project(url: project)
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: nil, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        projects.send(.projectsChanged)
        await waitFor { recorder.urls.count > before }

        #expect(recorder.urls.count > before)
    }

    @Test("提交选择与当前文件变化不触发预热")
    func commitAndFileEventsAreIgnored() async throws {
        let projects = EventProjects()
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: nil, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        projects.send(.commitSelectionChanged)
        projects.send(.currentFileChanged)
        try? await Task.sleep(nanoseconds: 150_000_000)

        #expect(recorder.urls.count == before)
    }

    @Test("仓库监听启动事件会作废快照并重新预热")
    func gitWatchStartedInvalidatesAndRefreshes() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: project)]
        let gitWatch = EventGitWatch()
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: gitWatch, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        gitWatch.send(.started(repositoryURL: project))
        await waitFor { recorder.urls.count > before }

        #expect(recorder.invalidatedURLs.contains(project.standardizedFileURL))
        #expect(recorder.urls.count > before)
    }

    @Test("仓库监听停止事件不触发预热")
    func gitWatchStoppedIsIgnored() async throws {
        let projects = EventProjects()
        let gitWatch = EventGitWatch()
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: gitWatch, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        gitWatch.send(.stopped)
        try? await Task.sleep(nanoseconds: 150_000_000)

        #expect(recorder.urls.count == before)
    }

    @Test("HEAD 变化事件会刷新当前项目")
    func headChangedRefreshesCurrentProject() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: project)]
        projects.currentProject = Project(url: project)
        let gitWatch = EventGitWatch()
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: gitWatch, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        gitWatch.send(.headChanged(previousHead: "a", head: "b"))
        await waitFor { recorder.urls.count > before }

        #expect(recorder.invalidatedURLs.contains(project.standardizedFileURL))
        #expect(recorder.urls.count > before)
    }

    @Test("项目数据变化会作废当前项目快照并重新预热")
    func dataChangedRefreshesCurrentProject() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let project = root.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: project)]
        projects.currentProject = Project(url: project)
        let recorder = PreheatLoadRecorder()
        let preheater = makePreheater(projects: projects, gitWatch: nil, recorder: recorder)
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        let before = recorder.urls.count

        projects.send(.dataChanged)
        await waitFor { recorder.urls.count > before }

        #expect(recorder.invalidatedURLs.contains(project.standardizedFileURL))
        #expect(recorder.urls.count > before)
    }

    @Test("单个项目加载失败不会阻塞其它项目")
    func failingProjectDoesNotBlockOthers() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let failing = root.appendingPathComponent("A", isDirectory: true)
        let healthy = root.appendingPathComponent("B", isDirectory: true)
        try FileManager.default.createDirectory(at: failing, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: healthy, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: failing), Project(url: healthy)]
        let recorder = PreheatLoadRecorder()
        let preheater = WorktreeSnapshotPreheater(
            projects: projects,
            loadSnapshot: { url, _ in
                recorder.append(url)
                if url.standardizedFileURL == failing.standardizedFileURL {
                    throw NSError(domain: "test", code: 1)
                }
            },
            invalidateSnapshot: { _ in },
            gitWatch: nil
        )
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 2 }

        #expect(recorder.urls.contains(healthy.standardizedFileURL))
    }

    @Test("加载抛出取消错误时立即结束本轮预热")
    func cancellationErrorStopsWorker() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-preheat-\(UUID().uuidString)", isDirectory: true)
        let first = root.appendingPathComponent("A", isDirectory: true)
        let second = root.appendingPathComponent("B", isDirectory: true)
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projects = EventProjects()
        projects.projects = [Project(url: first), Project(url: second)]
        let recorder = PreheatLoadRecorder()
        let preheater = WorktreeSnapshotPreheater(
            projects: projects,
            loadSnapshot: { url, _ in
                recorder.append(url)
                throw CancellationError()
            },
            invalidateSnapshot: { _ in },
            gitWatch: nil
        )
        preheater.start()
        defer { preheater.stop() }

        await waitFor { recorder.urls.count >= 1 }
        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(recorder.urls.count == 1)
    }
}
