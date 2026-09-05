import ProviderWorkspaceScene

@MainActor
final class GitUnpushedStatusSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any GitUnpushedStatusSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any GitUnpushedStatusSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
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
