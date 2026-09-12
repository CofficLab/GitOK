import Foundation
import ProviderActivityHeatmap

/// Worktree Clean's narrow view-facing boundary for activity data.
@MainActor
protocol WorktreeCleanActivityHeatmapCapability: AnyObject {
    var currentSnapshot: ActivityHeatmapSnapshot? { get }
    var isLoading: Bool { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ActivityHeatmapEvent) -> Void
    ) -> any ActivityHeatmapObserverHandle
}

/// Adapts the shared activity provider to the Worktree Clean UI boundary.
@MainActor
final class WorktreeCleanActivityHeatmapCapabilityAdapter: WorktreeCleanActivityHeatmapCapability {
    private let provider: any ActivityHeatmapProviding

    init(provider: any ActivityHeatmapProviding) {
        self.provider = provider
    }

    var currentSnapshot: ActivityHeatmapSnapshot? { provider.currentSnapshot }
    var isLoading: Bool { provider.isLoading }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ActivityHeatmapEvent) -> Void
    ) -> any ActivityHeatmapObserverHandle {
        provider.addObserver(callback)
    }
}
