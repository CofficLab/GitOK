import ProviderWorkspaceScene

/// Worktree Status 插件的场景观察者。
@MainActor
final class WorktreeStatusSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let onVisibilityChanged: (Bool) -> Void
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(
        scene: any WorkspaceSceneProviding,
        viewModel: WorkspaceSceneVisibilityViewModel,
        onVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.viewModel = viewModel
        self.onVisibilityChanged = onVisibilityChanged
        viewModel.handleSceneChange(scene.currentScene)
        onVisibilityChanged(viewModel.isActive)
        handle = scene.addObserver { [weak self] event in
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
