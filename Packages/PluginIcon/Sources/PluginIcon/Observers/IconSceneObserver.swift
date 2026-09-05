import ProviderWorkspaceScene

/// Icon 插件的场景观察者：把 WorkspaceSceneProviding 事件转换为插件场景 ViewModel 状态。
@MainActor
final class IconSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any IconSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any IconSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
        self.capability = capability
        self.viewModel = viewModel
        viewModel.handleSceneChange(capability.currentScene)
        handle = capability.addObserver { [weak self] event in
            guard case let .sceneChanged(_, scene) = event else { return }
            self?.viewModel?.handleSceneChange(scene)
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
    }
}
