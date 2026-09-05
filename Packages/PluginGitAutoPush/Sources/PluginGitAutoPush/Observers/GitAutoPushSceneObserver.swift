import ProviderWorkspaceScene

@MainActor
final class GitAutoPushSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any GitAutoPushSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any GitAutoPushSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
        self.capability = capability
        self.viewModel = viewModel
        viewModel.handleSceneChange(capability.currentScene)
        handle = capability.addObserver { [weak self] event in
            guard case let .sceneChanged(_, scene) = event else { return }
            self?.viewModel?.handleSceneChange(scene)
        }
    }

    func cancel() { handle?.cancel(); handle = nil }
}
