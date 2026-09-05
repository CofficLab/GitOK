import ProviderWorkspaceScene

/// Git Remote Repository 插件的场景观察者。
@MainActor
final class GitRemoteRepositorySceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(scene: any WorkspaceSceneProviding, viewModel: WorkspaceSceneVisibilityViewModel) {
        self.viewModel = viewModel
        viewModel.handleSceneChange(scene.currentScene)
        handle = scene.addObserver { [weak self] event in
            guard case let .sceneChanged(_, scene) = event else { return }
            self?.viewModel?.handleSceneChange(scene)
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
    }
}
