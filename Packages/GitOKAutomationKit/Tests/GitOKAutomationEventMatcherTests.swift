import Testing
@testable import GitOKAutomationKit

@Suite("GitOKAutomationEventMatcherTests")
struct GitOKAutomationEventMatcherTests {
    @Test("Commit matcher extracts hash only for commit action")
    func commitMatcherExtractsHashOnlyForCommitAction() {
        let matching = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockCommitSelected.rawValue,
            payload: ["hash": "abc123"]
        )
        let missingHash = GitOKAutomationRequest(action: GitOKAutomationAction.mockCommitSelected.rawValue)
        let wrongAction = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockFileSelected.rawValue,
            payload: ["hash": "abc123"]
        )

        #expect(GitOKAutomationEventMatcher.commitHash(from: matching) == "abc123")
        #expect(GitOKAutomationEventMatcher.commitHash(from: missingHash) == nil)
        #expect(GitOKAutomationEventMatcher.commitHash(from: wrongAction) == nil)
    }

    @Test("Working tree matcher only accepts working tree action")
    func workingTreeMatcherOnlyAcceptsWorkingTreeAction() {
        #expect(GitOKAutomationEventMatcher.isWorkingTreeSelected(.init(action: GitOKAutomationAction.mockWorkingTreeSelected.rawValue)))
        #expect(!GitOKAutomationEventMatcher.isWorkingTreeSelected(.init(action: GitOKAutomationAction.mockCommitSelected.rawValue)))
    }

    @Test("File and project matchers extract paths for matching actions")
    func fileAndProjectMatchersExtractPathsForMatchingActions() {
        let file = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockFileSelected.rawValue,
            payload: ["path": "APP/App.swift"]
        )
        let project = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockProjectSelected.rawValue,
            payload: ["path": "/tmp/repo"]
        )
        let emptyProjectPath = GitOKAutomationRequest(
            action: GitOKAutomationAction.mockProjectSelected.rawValue,
            payload: ["path": ""]
        )

        #expect(GitOKAutomationEventMatcher.filePath(from: file) == "APP/App.swift")
        #expect(GitOKAutomationEventMatcher.filePath(from: project) == nil)
        #expect(GitOKAutomationEventMatcher.projectPath(from: project) == "/tmp/repo")
        #expect(GitOKAutomationEventMatcher.projectPath(from: emptyProjectPath) == nil)
    }
}
