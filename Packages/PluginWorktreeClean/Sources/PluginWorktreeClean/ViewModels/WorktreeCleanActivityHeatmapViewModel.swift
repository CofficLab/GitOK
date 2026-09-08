import Foundation
import ProviderActivityHeatmap

/// View-owned snapshot of the activity capability.
@MainActor
final class WorktreeCleanActivityHeatmapViewModel: ObservableObject {
    @Published private(set) var snapshot: ActivityHeatmapSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var hasSelectedCommit = false
    @Published private(set) var projectURL: URL?

    func sync(from capability: any WorktreeCleanActivityHeatmapCapability) {
        snapshot = capability.currentSnapshot
        isLoading = capability.isLoading
    }

    func handleContextChanged(
        projectURL: URL?,
        hasSelectedCommit: Bool,
        capability: any WorktreeCleanActivityHeatmapCapability
    ) {
        self.projectURL = projectURL
        self.hasSelectedCommit = hasSelectedCommit
        sync(from: capability)
    }

    var isVisible: Bool {
        projectURL != nil && !hasSelectedCommit && (snapshot != nil || isLoading)
    }

    func level(for day: ActivityHeatmapDay) -> Int {
        guard day.commitCount > 0, let snapshot else { return 0 }
        let maximum = snapshot.days.map(\.commitCount).max() ?? 0
        guard maximum > 0 else { return 0 }
        if maximum <= 4 { return min(day.commitCount, 4) }
        let ratio = Double(day.commitCount) / Double(maximum)
        switch ratio {
        case 0.75...: return 4
        case 0.5...: return 3
        case 0.25...: return 2
        default: return 1
        }
    }
}
