import GitOKAppCore
import GitOKCoreKit

public enum AppTabCatalog {
    static var visibleTabs: [GitOKAppTab] {
        GitOKAppTab.sortedAllCases
    }

    static var defaultTab: GitOKAppTab {
        .git
    }
}
