import ProviderGitConflictResolver

/// 冲突插件对外提供的最小展示适配器。
@MainActor
final class GitConflictResolutionPresenter: GitConflictResolutionProviding {
    private weak var viewModel: GitConflictResolverViewModel?
    private let requestReload: @MainActor () -> Void

    init(
        viewModel: GitConflictResolverViewModel,
        requestReload: @escaping @MainActor () -> Void
    ) {
        self.viewModel = viewModel
        self.requestReload = requestReload
    }

    func requestPresentation() {
        requestReload()
        viewModel?.present()
    }
}
