import Foundation
import GitCoreKit
import GitOKCoreKit

public enum GitOKProjectServiceError: Error, Equatable, Sendable {
    case noCurrentProject
}

/// Plugin-facing project service facade (batch A: read-only Git state and inspection).
@MainActor
public protocol GitOKProjectServicing: AnyObject {
    // MARK: - Snapshot state (from ProjectVM / DataVM)

    var projectURL: URL? { get }
    var projectPath: String? { get }
    var projectTitle: String? { get }
    var branchName: String? { get }
    var isGitRepository: Bool { get }
    var selectedFilePath: String? { get }
    var remoteTrackingStatus: GitOKRemoteTrackingStatus? { get }
    var isClean: Bool { get }
    var unpushedCommitsCount: Int { get }
    var projectExists: Bool { get }
    var isCheckingGitRepository: Bool { get }
    var lastFetchedAt: Date? { get }

    // MARK: - Batch A read operations

    func refreshGitRepositoryState(reason: String)
    func refreshCurrentBranch(reason: String)
    func getCurrentBranch() throws -> GitBranch?
    func getBranches() throws -> [GitBranch]
    func lightweightStatusEntries() throws -> [GitStatusEntry]
    func lightweightStatusEntriesAsync() async throws -> [GitStatusEntry]
    func refreshStatus() async throws -> [GitStatusEntry]
    func hasStagedChangesAsync() async throws -> Bool
    func isGitAsync() async -> Bool
    func headCommitHashAsync() async -> String?
    func untrackedFiles() async throws -> [GitDiffFile]
    func stagedDiffFileList() async throws -> [GitDiffFile]
    func unstagedDiffFileList() async throws -> [GitDiffFile]
    func getUnPushedCommitCountAsync() async throws -> Int
    func aheadBehind() throws -> GitAheadBehind
    func aheadBehindAsync() async throws -> GitAheadBehind
}
