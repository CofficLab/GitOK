import Foundation
import ProviderProjects

/// 项目变化观察者：把 `ProjectProviding` 事件翻译成 ViewModel 的领域方法。
@MainActor
final class ProjectMissingObserver {
    private let capability: any ProjectMissingProjectCapability
    private weak var viewModel: ProjectMissingViewModel?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(
        capability: any ProjectMissingProjectCapability,
        viewModel: ProjectMissingViewModel
    ) {
        self.capability = capability
        self.viewModel = viewModel
        handle = capability.addProjectObserver { [weak self] event in
            switch event {
            case .selectionChanged, .projectsChanged:
                self?.viewModel?.handleProjectChanged(project: self?.capability.currentProject)
            default:
                break
            }
        }
        // 初始同步一次。
        viewModel.handleProjectChanged(project: capability.currentProject)
    }

    func cancel() {
        handle?.cancel()
        handle = nil
        viewModel = nil
    }
}
