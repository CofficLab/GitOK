import GitCoreKit
import GitOKCoreKit
@testable import GitStashPlugin
import Testing

@Suite("GitStashPlugin")
struct GitStashPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitStashPlugin.metadata.id == "GitStashPlugin")
        #expect(GitStashPlugin.metadata.iconName == "archivebox")
        #expect(GitStashPlugin.metadata.tableName == "Localizable")
    }

    @Test("display message prefers stash message")
    func displayMessagePrefersStashMessage() {
        let stash = GitStashEntry(index: 2, message: "save work")

        #expect(StashPresentation.displayMessage(for: stash, fallbackBranchName: "main") == "save work")
    }

    @Test("empty display message falls back to branch")
    func emptyDisplayMessageFallsBackToBranch() {
        let stash = GitStashEntry(index: 1, message: "", branchName: "feature/auth")

        #expect(StashPresentation.displayMessage(for: stash, fallbackBranchName: "main") == "WIP on feature/auth")
    }

    @Test("branch name sanitizes common separators")
    func branchNameSanitizesSeparators() {
        let stash = GitStashEntry(index: 3, message: "", branchName: "feature: login flow")

        #expect(StashPresentation.branchName(from: stash, fallbackBranchName: "main") == "stash/feature--login-flow-3")
    }

    @Test("pending actions require a clean working tree")
    func pendingActionsRequireCleanWorkingTree() {
        #expect(PendingStashAction.apply(index: 0).requiresCleanWorkingTree)
        #expect(PendingStashAction.pop(index: 0).requiresCleanWorkingTree)
        #expect(PendingStashAction.branch(index: 0, name: "stash/main-0").requiresCleanWorkingTree)
    }
}
