import Testing
@testable import ProviderWorkspaceScene

@Suite("ProviderWorkspaceScene")
@MainActor
struct ProviderWorkspaceSceneTests {
    @Test("默认场景为 Git")
    func defaultsToGit() {
        let provider = DefaultWorkspaceSceneProvider()

        #expect(provider.currentScene == .git)
        #expect(provider.availableScenes == [.git, .banner, .icon])
    }

    @Test("切换场景并广播旧值与新值")
    func changesSceneAndNotifies() {
        let provider = DefaultWorkspaceSceneProvider()
        var events: [WorkspaceSceneEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.selectScene(.banner)

        #expect(provider.currentScene == .banner)
        #expect(events == [.sceneChanged(from: .git, to: .banner)])
    }

    @Test("相同场景和未知场景不重复广播")
    func ignoresDuplicateAndUnavailableScenes() {
        let provider = DefaultWorkspaceSceneProvider(availableScenes: [.git, .banner])
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        provider.selectScene(.git)
        provider.selectScene(.icon)
        provider.selectScene(.banner)
        provider.selectScene(.banner)

        #expect(provider.currentScene == .banner)
        #expect(count == 1)
    }

    @Test("取消监听后不再接收事件")
    func cancellationStopsNotifications() {
        let provider = DefaultWorkspaceSceneProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        provider.selectScene(.banner)
        handle.cancel()
        provider.selectScene(.icon)

        #expect(count == 1)
    }

    @Test("初始场景不在可用列表时回退到第一个场景")
    func invalidInitialSceneFallsBack() {
        let provider = DefaultWorkspaceSceneProvider(
            initialScene: .icon,
            availableScenes: [.git, .banner]
        )

        #expect(provider.currentScene == .git)
    }

    @Test("插件场景 ViewModel 跟随场景 Provider 的变化")
    func pluginSceneViewModelTracksChanges() {
        let provider = DefaultWorkspaceSceneProvider()
        let viewModel = WorkspaceSceneVisibilityViewModel(targetScene: .banner)
        let handle = provider.addObserver { event in
            guard case let .sceneChanged(_, scene) = event else { return }
            viewModel.handleSceneChange(scene)
        }
        defer { handle.cancel() }

        #expect(!viewModel.isActive)
        provider.selectScene(.banner)
        #expect(viewModel.isActive)
    }

    @Test("场景选择器模型跟随 Provider 并可切换场景")
    func pickerModelTracksProvider() {
        let provider = DefaultWorkspaceSceneProvider()
        let model = WorkspaceScenePickerModel(provider: provider)

        model.select(.icon)

        #expect(provider.currentScene == .icon)
        #expect(model.selectedScene == .icon)
        #expect(model.availableScenes == [.git, .banner, .icon])
    }
}
