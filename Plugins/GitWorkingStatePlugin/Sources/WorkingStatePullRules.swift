import Foundation
import GitCoreKit

enum WorkingStatePullFailureDecision: Equatable {
    case suppressedForMergeConflict
    case offerStashAndPull(message: String)
    case presentRemoteFailure
}

enum WorkingStatePullRules {
    static func shouldOfferStashAndPull(for error: Error) -> Bool {
        GitOperationError.isLocalChangesWouldBeOverwritten(error)
    }

    static func pullBlockedAlertMessage(for error: Error) -> String {
        let localizedError = error as? LocalizedError
        return [localizedError?.errorDescription, localizedError?.recoverySuggestion]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: "\n\n")
    }

    static func pullFailureDecision(error: Error, isMerging: Bool) -> WorkingStatePullFailureDecision {
        if isMerging {
            return .suppressedForMergeConflict
        }
        if shouldOfferStashAndPull(for: error) {
            return .offerStashAndPull(message: pullBlockedAlertMessage(for: error))
        }
        return .presentRemoteFailure
    }

    static func runStashAndPull(
        stashSave: () async throws -> Void,
        onStashSaved: () -> Void,
        pull: () -> Void,
        onFailure: (Error) -> Void
    ) async {
        do {
            try await stashSave()
            onStashSaved()
            pull()
        } catch {
            onFailure(error)
        }
    }
}
