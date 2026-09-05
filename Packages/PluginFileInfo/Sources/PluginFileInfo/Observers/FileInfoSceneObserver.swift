import ProviderWorkspaceScene

@MainActor
final class FileInfoSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any FileInfoSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(capability: any FileInfoSceneCapability, viewModel: WorkspaceSceneVisibilityViewModel) {
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
