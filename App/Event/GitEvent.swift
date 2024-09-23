import Foundation

extension Notification.Name {
    static let gitPushing = Notification.Name("gitPushing")
    static let gitPulling = Notification.Name("gitPulling")
    static let gitPushSuccess = Notification.Name("gitPushSuccess")
    static let gitPushFailed = Notification.Name("gitPushFailed")
    static let gitPullSuccess = Notification.Name("gitPullSuccess")
    static let gitPullFailed = Notification.Name("gitPullFailed")
}

// MARK: Commit 

extension Notification.Name {
    static let gitCommitStart = Notification.Name("gitCommitStart")
    static let gitCommitSuccess = Notification.Name("gitCommitSuccess")
    static let gitCommitFailed = Notification.Name("gitCommitFailed")
}