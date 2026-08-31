import Foundation

extension Notification.Name {
    static let pluginUnpushedStatusAppDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let pluginUnpushedStatusProjectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    static let pluginUnpushedStatusProjectDidCommit = Notification.Name("projectDidCommit")
    static let pluginUnpushedStatusProjectDidFetch = Notification.Name("projectDidFetch")
    static let pluginUnpushedStatusProjectDidPush = Notification.Name("projectDidPush")
    static let pluginUnpushedStatusProjectDidPull = Notification.Name("projectDidPull")
    static let pluginUnpushedStatusProjectGitHeadDidChange = Notification.Name("projectGitHeadDidChange")
    static let pluginUnpushedStatusProjectGitRefsDidChange = Notification.Name("projectGitRefsDidChange")
}
