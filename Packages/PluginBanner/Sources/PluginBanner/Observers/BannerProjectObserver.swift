import ProviderProjects

/// 将项目选择变化映射为 Banner 工作区 ViewModel 的刷新。
@MainActor
final class BannerProjectObserver {
    private let capability: any BannerProjectCapability
    private weak var viewModel: BannerWorkspaceModel?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(
        capability: any BannerProjectCapability,
        viewModel: BannerWorkspaceModel
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
