import ProviderProjects

/// 将项目选择变化映射为 Icon 工作区 ViewModel 的刷新。
@MainActor
final class IconProjectObserver {
    private let capability: any IconProjectCapability
    private weak var viewModel: IconWorkspaceModel?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(
        capability: any IconProjectCapability,
        viewModel: IconWorkspaceModel
    ) {
        self.capability = capability
        self.viewModel = viewModel
        handle = capability.addObserver { [weak self] event in
            guard case .selectionChanged = event else { return }
            self?.viewModel?.reload()
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
        viewModel = nil
    }
}
