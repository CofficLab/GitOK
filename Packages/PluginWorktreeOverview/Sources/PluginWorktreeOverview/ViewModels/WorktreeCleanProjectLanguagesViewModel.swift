import Foundation
import ProviderProjectLanguages

/// View-owned snapshot of the project language capability.
@MainActor
final class WorktreeCleanProjectLanguagesViewModel: ObservableObject {
    @Published private(set) var snapshot: ProjectLanguagesSnapshot?
    @Published private(set) var isLoading = false

    var isVisible: Bool {
        snapshot != nil || isLoading
    }

    func sync(from capability: any WorktreeCleanProjectLanguagesCapability) {
        snapshot = capability.currentSnapshot
        isLoading = capability.isLoading
    }
}
