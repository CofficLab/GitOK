import Foundation
import ProviderWorkspaceScene

/// 场景观察者：把 `WorkspaceSceneProviding` 事件转换成插件场景 ViewModel 状态。
@MainActor
final class ProjectMissingSceneObserver {
    private weak var viewModel: WorkspaceSceneVisibilityViewModel?
    private let capability: any ProjectMissingSceneCapability
    private var handle: (any WorkspaceSceneObserverHandle)?

    init(
        capability: any ProjectMissingSceneCapability,
        viewModel: WorkspaceSceneVisibilityViewModel
    ) {
        self.capability = capability
        self.viewModel = viewModel
        handle = capability.addObserver { [weak self] event in
            switch event {
            case .sceneChanged(_, let toScene):
                self?.viewModel?.handleSceneChange(toScene)
            }
        }
        viewModel.handleSceneChange(capability.currentScene)
    }

    func cancel() {
        handle?.cancel()
        handle = nil
        viewModel = nil
    }
}
