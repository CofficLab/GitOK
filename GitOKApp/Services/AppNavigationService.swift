import GitOKAppCore
import Foundation
import GitOKCoreKit

@MainActor
final class AppNavigationService: GitOKNavigationServicing {
    private weak var appVM: AppVM?

    init(appVM: AppVM) {
        self.appVM = appVM
    }

    func openSettings(defaultTab: String?) {
        if let defaultTab {
            appVM?.defaultSettingTab = defaultTab
        }
        appVM?.openSettings()
    }

    func openSettings(tab: String?) {
        openSettings(defaultTab: tab)
    }

    func openPluginSettings() {
        appVM?.openPluginSettings()
    }

    func openRepositorySettings() {
        appVM?.openRepositorySettings()
    }

    func openCommitStyleSettings() {
        appVM?.openCommitStyleSettings()
    }
}
