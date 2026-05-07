import Foundation

enum ProjectEventRefreshRules {
    private static let stashOperations: Set<String> = [
        "stashSave",
        "stashApply",
        "stashPop",
        "stashDrop",
    ]

    static func shouldRefreshStash(for operation: String) -> Bool {
        stashOperations.contains(operation)
    }

    static func shouldRefreshConflictStatus(for notificationName: Notification.Name) -> Bool {
        notificationName.rawValue == "projectDidMerge" || notificationName.rawValue == "projectDidAddFiles"
    }
}
