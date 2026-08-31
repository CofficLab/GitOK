import Foundation

public enum ProjectEventRefreshRules {
    private static let stashOperations: Set<String> = [
        "stashSave",
        "stashApply",
        "stashPop",
        "stashDrop",
    ]

    public static func shouldRefreshStash(for operation: String) -> Bool {
        stashOperations.contains(operation)
    }

    public static func shouldRefreshConflictStatus(for notificationName: Notification.Name) -> Bool {
        notificationName.rawValue == "projectDidMerge" || notificationName.rawValue == "projectDidAddFiles"
    }
}
