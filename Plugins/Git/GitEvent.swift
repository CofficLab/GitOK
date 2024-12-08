import Foundation

// MARK: Pull

extension Notification.Name {
    static let gitPullStart = Notification.Name("gitPullStart")
    static let gitPullSuccess = Notification.Name("gitPullSuccess")
    static let gitPullFailed = Notification.Name("gitPullFailed")
}

// MARK: Push

extension Notification.Name {
    static let gitPushStart = Notification.Name("gitPushStart")
    static let gitPushSuccess = Notification.Name("gitPushSuccess")
    static let gitPushFailed = Notification.Name("gitPushFailed")
}

// MARK: Commit 

extension Notification.Name {
    static let gitCommitStart = Notification.Name("gitCommitStart")
    static let gitCommitSuccess = Notification.Name("gitCommitSuccess")
    static let gitCommitFailed = Notification.Name("gitCommitFailed")
}

// MARK: Branch

extension Notification.Name {
    static let gitBranchChanged = Notification.Name("gitBranchChanged")
}

// MARK: Project

extension Notification.Name {
    static let gitProjectDeleted = Notification.Name("gitProjectDeleted")
}
