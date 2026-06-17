@testable import GitBranchPlugin
import Foundation
import GitCoreKit
import Testing

@Suite("Mock BranchService Tests")
struct MockBranchServiceTests {

    // MARK: - currentBranchName

    @Test("MockBranchService returns configured currentBranchName")
    func currentBranchNameSuccess() throws {
        var mock = MockBranchService()
        mock.currentBranchNameResult = .success("develop")
        let result = try mock.currentBranchName()
        #expect(result == "develop")
    }

    @Test("MockBranchService returns nil currentBranchName")
    func currentBranchNameNil() throws {
        var mock = MockBranchService()
        mock.currentBranchNameResult = .success(nil)
        let result = try mock.currentBranchName()
        #expect(result == nil)
    }

    @Test("MockBranchService throws on currentBranchName error")
    func currentBranchNameError() {
        var mock = MockBranchService()
        mock.currentBranchNameResult = .failure(MockError(message: "not a repo"))
        #expect(throws: MockError.self) {
            try mock.currentBranchName()
        }
    }

    // MARK: - branches

    @Test("MockBranchService returns configured branches")
    func branchesSuccess() throws {
        var mock = MockBranchService()
        let expected = [
            GitBranchSummary(name: "main", isRemote: false, isCurrent: true),
            GitBranchSummary(name: "develop", isRemote: false, isCurrent: false),
        ]
        mock.branchesResult = .success(expected)
        let result = try mock.branches()
        #expect(result.count == 2)
        #expect(result[0].name == "main")
        #expect(result[1].name == "develop")
    }

    @Test("MockBranchService throws on branches error")
    func branchesError() {
        var mock = MockBranchService()
        mock.branchesResult = .failure(MockError(message: "git failed"))
        #expect(throws: MockError.self) {
            try mock.branches()
        }
    }

    // MARK: - remoteBranches

    @Test("MockBranchService returns configured remote branches")
    func remoteBranchesSuccess() throws {
        var mock = MockBranchService()
        mock.remoteBranchesResult = .success(["origin/main", "origin/develop"])
        let result = try mock.remoteBranches()
        #expect(result.count == 2)
    }

    // MARK: - remotes

    @Test("MockBranchService returns configured remotes")
    func remotesSuccess() throws {
        var mock = MockBranchService()
        let expected = [
            GitRemoteSummary(id: "1", name: "origin", url: "https://github.com/a/b.git", fetchURL: nil, pushURL: nil, isDefault: true),
        ]
        mock.remotesResult = .success(expected)
        let result = try mock.remotes()
        #expect(result.count == 1)
        #expect(result[0].name == "origin")
    }

    // MARK: - createBranch

    @Test("MockBranchService calls createBranch action")
    func createBranchAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.createBranchAction = { name in captured = name }
        try mock.createBranch(named: "feature/new")
        #expect(captured == "feature/new")
    }

    @Test("MockBranchService createBranch with no action does nothing")
    func createBranchNoAction() throws {
        let mock = MockBranchService()
        try mock.createBranch(named: "feature/new")
    }

    // MARK: - checkoutBranch

    @Test("MockBranchService calls checkoutBranch action")
    func checkoutBranchAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.checkoutBranchAction = { name in captured = name }
        try mock.checkoutBranch(named: "develop")
        #expect(captured == "develop")
    }

    // MARK: - deleteLocalBranch

    @Test("MockBranchService calls deleteLocalBranch action")
    func deleteLocalBranchAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.deleteLocalBranchAction = { name in captured = name }
        try mock.deleteLocalBranch(named: "old-branch")
        #expect(captured == "old-branch")
    }

    // MARK: - deleteRemoteBranch

    @Test("MockBranchService calls deleteRemoteBranch action with both args")
    func deleteRemoteBranchAction() throws {
        nonisolated(unsafe) var capturedBranch = ""
        nonisolated(unsafe) var capturedRemote = ""
        var mock = MockBranchService()
        mock.deleteRemoteBranchAction = { branch, remote in
            capturedBranch = branch
            capturedRemote = remote
        }
        try mock.deleteRemoteBranch(named: "feature", remote: "origin")
        #expect(capturedBranch == "feature")
        #expect(capturedRemote == "origin")
    }

    // MARK: - renameBranch

    @Test("MockBranchService calls renameBranch action")
    func renameBranchAction() throws {
        nonisolated(unsafe) var capturedOld = ""
        nonisolated(unsafe) var capturedNew = ""
        var mock = MockBranchService()
        mock.renameBranchAction = { old, new in
            capturedOld = old
            capturedNew = new
        }
        try mock.renameBranch(from: "old", to: "new")
        #expect(capturedOld == "old")
        #expect(capturedNew == "new")
    }

    // MARK: - setUpstream

    @Test("MockBranchService calls setUpstream action")
    func setUpstreamAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.setUpstreamAction = { local, upstream in captured = upstream }
        try mock.setUpstream(localBranch: "feature", upstreamBranch: "origin/feature")
        #expect(captured == "origin/feature")
    }

    // MARK: - unsetUpstream

    @Test("MockBranchService calls unsetUpstream action")
    func unsetUpstreamAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.unsetUpstreamAction = { local in captured = local }
        try mock.unsetUpstream(localBranch: "feature")
        #expect(captured == "feature")
    }

    // MARK: - publishBranch

    @Test("MockBranchService calls publishBranch action")
    func publishBranchAction() throws {
        nonisolated(unsafe) var captured = ""
        var mock = MockBranchService()
        mock.publishBranchAction = { name in captured = name }
        try mock.publishBranch(localBranch: "feature")
        #expect(captured == "feature")
    }

    // MARK: - compareBranches

    @Test("MockBranchService returns configured compare result")
    func compareBranchesSuccess() throws {
        var mock = MockBranchService()
        let expected = GitBranchCompare(
            base: "main", head: "feature", ahead: 3, behind: 1,
            commits: [
                GitBranchCompareCommit(hash: "abc123", author: "Test", date: Date(), subject: "Fix bug")
            ],
            files: [
                GitBranchCompareFile(status: "M", path: "file.swift")
            ]
        )
        mock.compareBranchesResult = .success(expected)
        let result = try mock.compareBranches(base: "main", head: "feature")
        #expect(result.ahead == 3)
        #expect(result.behind == 1)
        #expect(result.commits.count == 1)
        #expect(result.files.count == 1)
    }

    @Test("MockBranchService throws on compareBranches error")
    func compareBranchesError() {
        var mock = MockBranchService()
        mock.compareBranchesResult = .failure(MockError(message: "compare failed"))
        #expect(throws: MockError.self) {
            try mock.compareBranches(base: "main", head: "feature")
        }
    }

    // MARK: - mergeBranches

    @Test("MockBranchService calls mergeBranches action")
    func mergeBranchesAction() throws {
        nonisolated(unsafe) var capturedFrom = ""
        nonisolated(unsafe) var capturedTo = ""
        var mock = MockBranchService()
        mock.mergeBranchesAction = { from, to in
            capturedFrom = from
            capturedTo = to
        }
        try mock.mergeBranches(fromBranch: "feature", toBranch: "main")
        #expect(capturedFrom == "feature")
        #expect(capturedTo == "main")
    }

    // MARK: - MockError

    @Test("MockError has localized description")
    func mockErrorDescription() {
        let error = MockError(message: "test error")
        #expect(error.errorDescription == "test error")
    }
}
