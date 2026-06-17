@testable import GitBranchPlugin
import Foundation
import GitCoreKit
import Testing

// MARK: - Mock BranchService

struct MockBranchService: BranchService {
    var currentBranchNameResult: Result<String?, Error> = .success("main")
    var branchesResult: Result<[GitBranchSummary], Error> = .success([])
    var remoteBranchesResult: Result<[String], Error> = .success([])
    var remotesResult: Result<[GitRemoteSummary], Error> = .success([])

    var createBranchAction: (@Sendable (String) throws -> Void)?
    var checkoutBranchAction: (@Sendable (String) throws -> Void)?
    var deleteLocalBranchAction: (@Sendable (String) throws -> Void)?
    var deleteRemoteBranchAction: (@Sendable (String, String) throws -> Void)?
    var renameBranchAction: (@Sendable (String, String) throws -> Void)?
    var setUpstreamAction: (@Sendable (String, String) throws -> Void)?
    var unsetUpstreamAction: (@Sendable (String) throws -> Void)?
    var publishBranchAction: (@Sendable (String) throws -> Void)?
    var compareBranchesResult: Result<GitBranchCompare, Error> = .success(
        GitBranchCompare(base: "main", head: "feature", ahead: 1, behind: 0, commits: [], files: [])
    )
    var mergeBranchesAction: (@Sendable (String, String) throws -> Void)?

    func currentBranchName() throws -> String? {
        try currentBranchNameResult.get()
    }

    func branches() throws -> [GitBranchSummary] {
        try branchesResult.get()
    }

    func remoteBranches() throws -> [String] {
        try remoteBranchesResult.get()
    }

    func remotes() throws -> [GitRemoteSummary] {
        try remotesResult.get()
    }

    func createBranch(named name: String) throws {
        try createBranchAction?(name)
    }

    func checkoutBranch(named name: String) throws {
        try checkoutBranchAction?(name)
    }

    func deleteLocalBranch(named name: String) throws {
        try deleteLocalBranchAction?(name)
    }

    func deleteRemoteBranch(named name: String, remote: String) throws {
        try deleteRemoteBranchAction?(name, remote)
    }

    func renameBranch(from old: String, to new: String) throws {
        try renameBranchAction?(old, new)
    }

    func setUpstream(localBranch: String, upstreamBranch: String) throws {
        try setUpstreamAction?(localBranch, upstreamBranch)
    }

    func unsetUpstream(localBranch: String) throws {
        try unsetUpstreamAction?(localBranch)
    }

    func publishBranch(localBranch: String) throws {
        try publishBranchAction?(localBranch)
    }

    func compareBranches(base: String, head: String) throws -> GitBranchCompare {
        try compareBranchesResult.get()
    }

    func mergeBranches(fromBranch: String, toBranch: String) throws {
        try mergeBranchesAction?(fromBranch, toBranch)
    }
}

struct MockError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
