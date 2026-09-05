import ProviderWorkspaceScene

/// Git Branch Status 插件的场景观察者。
@MainActor
final class GitBranchStatusSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any GitBranchStatusSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any GitBranchStatusSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
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
