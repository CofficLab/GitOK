import Foundation

struct ProjectGitOperationEventDescriptor {
    let notificationName: Notification.Name
    let operation: String
    let success: Bool
    let error: Error?
    let additionalInfo: [String: Any]?

    static func stashSaveSuccess(message: String?) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashSave",
            success: true,
            error: nil,
            additionalInfo: ["message": message ?? ""]
        )
    }

    static func stashSaveFailure(message: String?, error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashSave",
            success: false,
            error: error,
            additionalInfo: ["message": message ?? ""]
        )
    }

    static func stashApplySuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashApply",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    static func stashApplyFailure(index: Int, error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashApply",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    static func stashPopSuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashPop",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    static func stashPopFailure(index: Int, error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashPop",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    static func stashDropSuccess(index: Int) -> Self {
        Self(
            notificationName: Notification.Name("projectDidCommit"),
            operation: "stashDrop",
            success: true,
            error: nil,
            additionalInfo: ["index": index]
        )
    }

    static func stashDropFailure(index: Int, error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "stashDrop",
            success: false,
            error: error,
            additionalInfo: ["index": index]
        )
    }

    static func abortMergeSuccess() -> Self {
        Self(
            notificationName: Notification.Name("projectDidMerge"),
            operation: "abortMerge",
            success: true,
            error: nil,
            additionalInfo: nil
        )
    }

    static func abortMergeFailure(error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "abortMerge",
            success: false,
            error: error,
            additionalInfo: nil
        )
    }

    static func continueMergeSuccess(branchName: String) -> Self {
        Self(
            notificationName: Notification.Name("projectDidMerge"),
            operation: "continueMerge",
            success: true,
            error: nil,
            additionalInfo: ["branchName": branchName]
        )
    }

    static func continueMergeFailure(branchName: String, error: Error) -> Self {
        Self(
            notificationName: Notification.Name("projectOperationDidFail"),
            operation: "continueMerge",
            success: false,
            error: error,
            additionalInfo: ["branchName": branchName]
        )
    }
}
