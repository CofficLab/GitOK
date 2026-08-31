import Foundation

extension Notification.Name {
    static let pluginStashAppDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let pluginStashProjectDidCommit = Notification.Name("projectDidCommit")
    static let pluginStashProjectGitStashDidChange = Notification.Name("projectGitStashDidChange")
}
