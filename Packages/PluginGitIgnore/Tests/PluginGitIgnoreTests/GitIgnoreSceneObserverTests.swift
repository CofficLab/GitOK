import Foundation
import KitGit
import ProviderProjects
import ProviderWorkspaceScene
import Testing

@testable import PluginGitIgnore

// MARK: - Test Doubles

/// 可手动派发场景事件的 `WorkspaceSceneProviding` 替身。
@MainActor
private final class MockSceneProvider: WorkspaceSceneProviding {
    var currentScene: GitOKWorkspaceScene
    let availableScenes: [GitOKWorkspaceScene] = [.git, .banner, .icon]
    private(set) var observerCount = 0
    private var subscriptions: [UUID: (WorkspaceSceneEvent) -> Void] = [:]

    init(currentScene: GitOKWorkspaceScene = .git) {
        self.currentScene = currentScene
    }

    func selectScene(_ scene: GitOKWorkspaceScene) {
        guard scene != currentScene else { return }
        let from = currentScene
        currentScene = scene
        let event = WorkspaceSceneEvent.sceneChanged(from: from, to: scene)
        subscriptions.values.forEach { $0(event) }
    }

    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        let token = UUID()
        observerCount += 1
        subscriptions[token] = callback
        // 真实 Provider 的 handle 在 cancel 后不再收到回调，这里保持一致。
        return MockSceneHandle { [weak self] in
            self?.subscriptions[token] = nil
            self?.observerCount -= 1
        }
    }
}

@MainActor
private final class MockSceneHandle: WorkspaceSceneObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

// MARK: - Tests

@Suite("GitIgnore 场景能力与观察者")
@MainActor
struct GitIgnoreSceneObserverTests {

    @Test("Adapter 透传当前场景")
    func adapterForwardsCurrentScene() {
        let provider = MockSceneProvider(currentScene: .icon)
        let adapter = GitIgnoreSceneCapabilityAdapter(scene: provider)

        #expect(adapter.currentScene == .icon)
    }

    @Test("Adapter 透传事件订阅")
    func adapterForwardsObserverRegistration() {
        let provider = MockSceneProvider(currentScene: .banner)
        let adapter = GitIgnoreSceneCapabilityAdapter(scene: provider)

        adapter.addObserver { _ in }

        #expect(provider.observerCount == 1)
    }

    @Test("初始化时立即用当前场景同步一次可见性")
    func syncInitialSceneOnInit() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)

        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }

        // 初始场景 banner 非目标场景 git，item 应不可见。
        #expect(viewModel.isActive == false)
    }

    @Test("场景切换为目标场景时变为可见")
    func becomesVisibleOnMatchingScene() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }

        provider.selectScene(.git)

        #expect(viewModel.isActive)
    }

    @Test("切离目标场景后变为不可见")
    func becomesHiddenWhenLeavingTargetScene() {
        let provider = MockSceneProvider(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }
        #expect(viewModel.isActive)

        provider.selectScene(.icon)

        #expect(viewModel.isActive == false)
    }

    @Test("重复切换到当前场景不触发额外更新")
    func reselectingSameSceneIsNoop() {
        let provider = MockSceneProvider(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        defer { observer.cancel() }

        provider.selectScene(.git)

        #expect(viewModel.isActive)
    }

    @Test("cancel 后不再接收场景事件")
    func cancelStopsForwarding() {
        let provider = MockSceneProvider(currentScene: .banner)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )
        observer.cancel()

        provider.selectScene(.git)

        #expect(viewModel.isActive == false)
    }

    @Test("cancel 可重复调用且幂等")
    func cancelIsIdempotent() {
        let provider = MockSceneProvider(currentScene: .git)
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let observer = GitIgnoreSceneObserver(
            capability: GitIgnoreSceneCapabilityAdapter(scene: provider),
            viewModel: viewModel
        )

        observer.cancel()
        observer.cancel()

        #expect(viewModel.isActive)
    }
}

// MARK: - Project Observation

/// 可手动派发项目事件的 `ProjectProviding` 替身。
@MainActor
private final class MockProjectsProvider: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    private(set) var observerCount = 0
    private var callbacks: [(ProjectProvidingEvent) -> Void] = []

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ path: String?) {}
    func clearCommitSelection() {}

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        observerCount += 1
        callbacks.append(callback)
        return MockProjectHandle { [weak self] in
            guard let self else { return }
            self.observerCount -= 1
        }
    }

    func emit(_ event: ProjectProvidingEvent) {
        callbacks.forEach { $0(event) }
    }
}

@MainActor
private final class MockProjectHandle: ProjectProvidingObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

@Suite("ProjectObservationModel")
@MainActor
struct ProjectObservationModelTests {

    @Test("订阅后建立观察者")
    func registersObserver() {
        let provider = MockProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        #expect(provider.observerCount == 1)
        _ = model
    }

    @Test("收到事件时记录事件并递增 revision")
    func recordsEventAndBumpsRevision() {
        let provider = MockProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        provider.emit(.dataChanged)
        #expect(model.revision == 1)
        if case .dataChanged = model.lastEvent {} else {
            Issue.record("lastEvent 应为 dataChanged，实际为 \(String(describing: model.lastEvent))")
        }

        provider.emit(.projectsChanged)
        #expect(model.revision == 2)
        if case .projectsChanged = model.lastEvent {} else {
            Issue.record("lastEvent 应为 projectsChanged，实际为 \(String(describing: model.lastEvent))")
        }
    }

    @Test("无事件时 revision 与 lastEvent 保持初始值")
    func initialState() {
        let provider = MockProjectsProvider()
        let model = ProjectObservationModel(projects: provider)

        #expect(model.revision == 0)
        #expect(model.lastEvent == nil)
    }
}
