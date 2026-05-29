import Foundation

extension Notification.Name {
    static let pluginCleanStatusAppDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let pluginCleanStatusProjectDidAddFiles = Notification.Name("projectDidAddFiles")
    static let pluginCleanStatusProjectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    static let pluginCleanStatusProjectDidCommit = Notification.Name("projectDidCommit")
    static let pluginCleanStatusProjectDidMerge = Notification.Name("projectDidMerge")
    static let pluginCleanStatusProjectDidPull = Notification.Name("projectDidPull")
    static let pluginCleanStatusProjectDidPush = Notification.Name("projectDidPush")
    static let pluginCleanStatusProjectDidSync = Notification.Name("projectDidSync")
    static let pluginCleanStatusProjectGitHeadDidChange = Notification.Name("projectGitHeadDidChange")
    static let pluginCleanStatusProjectGitIndexDidChange = Notification.Name("projectGitIndexDidChange")
}
