import KitGit
import SwiftUI

/// Fixed colors for file-change accents.
///
/// These colors intentionally do not use `LumiUITheme` semantic colors because
/// the change type should remain recognizable when the app theme changes.
enum CommitDetailChangeColors {
    static let added = Color(red: 0.204, green: 0.780, blue: 0.349)       // #34C759
    static let deleted = Color(red: 1.000, green: 0.275, blue: 0.227)    // #FF453A
    static let modified = Color(red: 0.039, green: 0.518, blue: 1.000)   // #0A84FF
    static let renamed = Color(red: 0.686, green: 0.322, blue: 0.871)    // #AF52DE
    static let conflict = Color(red: 1.000, green: 0.624, blue: 0.039)   // #FF9F0A
    static let unknown = Color(red: 0.557, green: 0.557, blue: 0.576)    // #8E8E93

    static func commitStatus(_ status: GitFileChange.Status) -> Color {
        switch status {
        case .added:
            return added
        case .deleted:
            return deleted
        case .modified:
            return modified
        case .renamed, .copied:
            return renamed
        case .unmerged:
            return conflict
        case .unknown:
            return unknown
        }
    }

    static func worktreeStatus(_ entry: GitStatusEntry) -> Color {
        if entry.isUntracked { return conflict }

        // 工作区同时存在暂存和未暂存变更时，以最新的工作区状态为准。
        let status = entry.isWorktreeModified ? entry.worktreeStatus : entry.stagedStatus
        switch status {
        case "A":
            return added
        case "D":
            return deleted
        case "M":
            return modified
        case "R", "C":
            return renamed
        case "U":
            return conflict
        default:
            return unknown
        }
    }
}
