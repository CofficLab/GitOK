import ProviderWorkspaceScene

/// Commit List 插件的场景观察者。
@MainActor
final class CommitListSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any CommitListSceneCapability
    private let onVisibilityChanged: (Bool) -> Void
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(
        capability: any CommitListSceneCapability,
        viewModel: WorkspaceSceneVisibilityViewModel,
        onVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.capability = capability
        self.viewModel = viewModel
        self.onVisibilityChanged = onVisibilityChanged
        viewModel.handleSceneChange(capability.currentScene)
        onVisibilityChanged(viewModel.isActive)
        handle = capability.addObserver { [weak self] event in
            guard case let .sceneChanged(_, scene) = event else { return }
            guard let self, let viewModel = self.viewModel else { return }
            viewModel.handleSceneChange(scene)
            self.onVisibilityChanged(viewModel.isActive)
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
    }
}
