/// Navigation actions exposed to plugins, commands, and host chrome.
@MainActor
public protocol GitOKNavigationServicing: AnyObject {
    func openSettings(defaultTab: String?)
    func openSettings(tab: String?)
    func openPluginSettings()
    func openRepositorySettings()
    func openCommitStyleSettings()
}
