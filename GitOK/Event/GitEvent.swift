import Foundation

extension Notification.Name {
    static let gitPushing = Notification.Name("gitPushing")
    static let gitPulling = Notification.Name("gitPulling")
    static let gitPushSuccess = Notification.Name("gitPushSuccess")
    static let gitPushFailed = Notification.Name("gitPushFailed")
    static let gitPullSuccess = Notification.Name("gitPullSuccess")
    static let gitPullFailed = Notification.Name("gitPullFailed")
}