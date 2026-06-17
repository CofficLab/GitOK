import GitOKAppCore
import GitOKCoreKit

enum AppTabCatalog {
    static var visibleTabs: [GitOKAppTab] {
        GitOKAppTab.sortedAllCases
    }

    static var defaultTab: GitOKAppTab {
        .git
    }
}
