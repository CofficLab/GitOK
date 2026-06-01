import Foundation
import GitCoreKit
import GitOKCoreKit

public enum StashPresentation {
    public static func displayMessage(for stash: GitStashEntry, fallbackBranchName: String) -> String {
        let trimmed = stash.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty == false {
            return trimmed
        }
        return PluginStashLocalization.string("WIP on %@", displayBranchName(for: stash, fallbackBranchName: fallbackBranchName))
    }

    public static func displayBranchName(for stash: GitStashEntry, fallbackBranchName: String) -> String {
        let branchName = stash.branchName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if branchName.isEmpty == false {
            return branchName
        }
        let fallback = fallbackBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? "main" : fallback
    }

    public static func branchName(from stash: GitStashEntry, fallbackBranchName: String) -> String {
        let sourceBranch = displayBranchName(for: stash, fallbackBranchName: fallbackBranchName)
        let normalized = sourceBranch
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        return "stash/\(normalized)-\(stash.index)"
    }

    public static func fileCountText(_ count: Int) -> String {
        PluginStashLocalization.string("%lld files", count)
    }
}

enum PendingStashAction: Equatable {
    case apply(index: Int)
    case pop(index: Int)
    case branch(index: Int, name: String)

    var stashIndex: Int {
        switch self {
        case let .apply(index), let .pop(index), let .branch(index, _):
            return index
        }
    }

    var requiresCleanWorkingTree: Bool {
        true
    }
}
