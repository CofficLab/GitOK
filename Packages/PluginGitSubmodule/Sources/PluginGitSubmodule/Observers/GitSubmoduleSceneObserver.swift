import ProviderWorkspaceScene

/// Git Submodule 插件的场景观察者。
@MainActor
final class GitSubmoduleSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any GitSubmoduleSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any GitSubmoduleSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
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
