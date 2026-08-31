import Foundation

extension Notification.Name {
    static let pluginConflictResolverAppDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let pluginConflictResolverProjectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    static let pluginConflictResolverProjectDidCommit = Notification.Name("projectDidCommit")
    static let pluginConflictResolverProjectDidMerge = Notification.Name("projectDidMerge")
    static let pluginConflictResolverProjectDidPull = Notification.Name("projectDidPull")
    static let pluginConflictResolverProjectGitHeadDidChange = Notification.Name("projectGitHeadDidChange")
    static let pluginConflictResolverProjectGitIndexDidChange = Notification.Name("projectGitIndexDidChange")
}
