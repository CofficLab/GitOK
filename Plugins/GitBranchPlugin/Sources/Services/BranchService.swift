import Foundation
import GitCoreKit

// MARK: - Protocol

protocol BranchService: Sendable {
    func currentBranchName() throws -> String?
    func branches() throws -> [GitBranchSummary]
    func remoteBranches() throws -> [String]
    func remotes() throws -> [GitRemoteSummary]
    func createBranch(named: String) throws
    func checkoutBranch(named: String) throws
    func deleteLocalBranch(named: String) throws
    func deleteRemoteBranch(named: String, remote: String) throws
    func renameBranch(from: String, to: String) throws
    func setUpstream(localBranch: String, upstreamBranch: String) throws
    func unsetUpstream(localBranch: String) throws
    func publishBranch(localBranch: String) throws
    func compareBranches(base: String, head: String) throws -> GitBranchCompare
    func mergeBranches(fromBranch: String, toBranch: String) throws
}

// MARK: - Live Implementation

struct LiveBranchService: BranchService {
    let repositoryURL: URL

    init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
    }

    private func repo() -> GitRepositoryCLI {
        GitRepositoryCLI(repositoryURL: repositoryURL)
    }

    func currentBranchName() throws -> String? {
        try repo().currentBranchName()
    }

    func branches() throws -> [GitBranchSummary] {
        try repo().branches()
    }

    func remoteBranches() throws -> [String] {
        try repo().remoteBranches()
    }

    func remotes() throws -> [GitRemoteSummary] {
        try repo().remotes()
    }

    func createBranch(named: String) throws {
        try repo().createBranch(named: named)
    }

    func checkoutBranch(named: String) throws {
        try repo().checkoutBranch(named: named)
    }

    func deleteLocalBranch(named: String) throws {
        try repo().deleteLocalBranch(named: named)
    }

    func deleteRemoteBranch(named: String, remote: String) throws {
        try repo().deleteRemoteBranch(named: named, remote: remote)
    }

    func renameBranch(from: String, to: String) throws {
        try repo().renameBranch(from: from, to: to)
    }

    func setUpstream(localBranch: String, upstreamBranch: String) throws {
        try repo().setUpstream(localBranch: localBranch, upstreamBranch: upstreamBranch)
    }

    func unsetUpstream(localBranch: String) throws {
        try repo().unsetUpstream(localBranch: localBranch)
    }

    func publishBranch(localBranch: String) throws {
        try repo().publishBranch(localBranch: localBranch)
    }

    func compareBranches(base: String, head: String) throws -> GitBranchCompare {
        try repo().compareBranches(base: base, head: head)
    }

    func mergeBranches(fromBranch: String, toBranch: String) throws {
        try repo().mergeBranches(fromBranch: fromBranch, toBranch: toBranch)
    }
}
