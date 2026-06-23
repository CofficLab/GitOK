import Foundation
@testable import GitWorkingStatePlugin
import Testing

@Suite("GitWorkingStatePlugin")
struct GitWorkingStatePluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(GitWorkingStatePlugin.metadata.id == "GitWorkingStatePlugin")
        #expect(GitWorkingStatePlugin.metadata.iconName == "tray.2")
        #expect(GitWorkingStatePlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitWorkingStatePlugin.metadata.displayName.isEmpty == false)
        #expect(GitWorkingStatePlugin.metadata.description.isEmpty == false)
    }

    @Test("pull blocked alert message combines description and recovery suggestion")
    func pullBlockedAlertMessage() {
        let error = TestLocalizedError(
            description: "Local changes would be overwritten",
            suggestion: "Commit or stash your changes before continuing"
        )
        #expect(
            WorkingStatePullRules.pullBlockedAlertMessage(for: error)
                == "Local changes would be overwritten\n\nCommit or stash your changes before continuing"
        )
    }

    @Test("pull failure decision suppresses alert while merging")
    func pullFailureDecisionSuppressesDuringMerge() {
        let error = TestLocalizedError(description: "blocked", suggestion: nil)
        #expect(
            WorkingStatePullRules.pullFailureDecision(error: error, isMerging: true)
                == .suppressedForMergeConflict
        )
    }

    @Test("pull failure decision falls back to remote failure for other errors")
    func pullFailureDecisionFallsBackToRemoteFailure() {
        #expect(
            WorkingStatePullRules.pullFailureDecision(error: TestError(), isMerging: false)
                == .presentRemoteFailure
        )
    }

    @Test("runStashAndPull stashes before pulling")
    func runStashAndPullOrder() async {
        var stashCalled = false
        var refreshCalled = false
        var pullCalled = false

        await WorkingStatePullRules.runStashAndPull(
            stashSave: {
                #expect(pullCalled == false)
                stashCalled = true
            },
            onStashSaved: { refreshCalled = true },
            pull: {
                #expect(stashCalled)
                pullCalled = true
            },
            onFailure: { _ in Issue.record("stash should succeed") }
        )

        #expect(stashCalled)
        #expect(refreshCalled)
        #expect(pullCalled)
    }

    @Test("runStashAndPull reports stash failure without pulling")
    func runStashAndPullStashFailure() async {
        var pullCalled = false
        var reportedError: Error?

        await WorkingStatePullRules.runStashAndPull(
            stashSave: { throw TestError() },
            onStashSaved: { Issue.record("stash failed") },
            pull: { pullCalled = true },
            onFailure: { reportedError = $0 }
        )

        #expect(pullCalled == false)
        #expect(reportedError is TestError)
    }
}

private struct TestError: Error {}

private struct TestLocalizedError: LocalizedError {
    let description: String
    let suggestion: String?

    var errorDescription: String? { description }
    var recoverySuggestion: String? { suggestion }
}
