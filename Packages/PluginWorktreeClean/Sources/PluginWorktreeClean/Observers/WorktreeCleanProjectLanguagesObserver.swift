import ProviderProjectLanguages

/// Translates provider updates into the Worktree Clean view model.
@MainActor
final class WorktreeCleanProjectLanguagesObserver {
    private var handle: (any ProjectLanguagesObserverHandle)?

    init(
        capability: any WorktreeCleanProjectLanguagesCapability,
        viewModel: WorktreeCleanProjectLanguagesViewModel
    ) {
        viewModel.sync(from: capability)
        handle = capability.addObserver { [weak viewModel, capability] _ in
            viewModel?.sync(from: capability)
        }
    }

    func cancel() {
        handle?.cancel()
        handle = nil
    }
}
