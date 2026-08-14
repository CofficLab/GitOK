import GitOKAppCore
import Foundation
import GitOKCoreKit

@MainActor
public final class AppNavigationService: GitOKNavigationServicing {
    private weak var appVM: AppVM?

    public init(appVM: AppVM) {
        self.appVM = appVM
    }

    public func openSettings(defaultTab: String?) {
        if let defaultTab {
            appVM?.defaultSettingTab = defaultTab
        }
        appVM?.openSettings()
    }

    public func openSettings(tab: String?) {
        openSettings(defaultTab: tab)
    }

    public func openPluginSettings() {
        appVM?.openPluginSettings()
    }

    public func openRepositorySettings() {
        appVM?.openRepositorySettings()
    }

    public func openCommitStyleSettings() {
        appVM?.openCommitStyleSettings()
    }
}
