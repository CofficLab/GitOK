import Foundation

public struct ProjectGitOperationEventDescriptor {
    public let notificationName: Notification.Name
    public let operation: String
    public let success: Bool
    public let error: (any Error)?
    public let additionalInfo: [String: Any]?

    public static func stashSaveSuccess(message: String?) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashSave",
            success: true,
            error: nil,
            additionalInfo: ["message": message ?? ""]
        )
    }

    public static func stashSaveFailure(message: String?, error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashSave",
            success: false,
            error: error,
            additionalInfo: ["message": message ?? ""]
        )
    }

    public static func stashApplySuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashApply",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    public static func stashApplyFailure(index: Int, error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashApply",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    public static func stashPopSuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashPop",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    public static func stashPopFailure(index: Int, error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashPop",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    public static func stashDropSuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashDrop",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    public static func stashDropFailure(index: Int, error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashDrop",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    public static func abortMergeSuccess() -> Self {
        Self(
            notificationName: Notification.Name("projectDidMerge"),
            operation: "abortMerge",
            success: true,
            error: nil,
            additionalInfo: nil
        )
    }

    public static func abortMergeFailure(error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "abortMerge",
            success: false,
            error: error,
            additionalInfo: nil
        )
    }

    public static func continueMergeSuccess(branchName: String) -> Self {
        Self(
            notificationName: Notification.Name("projectDidMerge"),
            operation: "continueMerge",
            success: true,
            error: nil,
            additionalInfo: ["branchName": branchName]
        )
    }

    public static func continueMergeFailure(branchName: String, error: any Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "continueMerge",
            success: false,
            error: error,
            additionalInfo: ["branchName": branchName]
        )
    }
}
