import Foundation
import GitCoreKit

/// Read-only Git project operations that `Project` implements in the App layer.
/// Batch A: status, branch, and working-tree inspection (no writes).
@MainActor
public protocol GitOKProjectModeling: AnyObject {
    var url: URL { get }
    var path: String { get }
    var title: String { get }
    var isGitRepo: Bool { get }

    func getCurrentBranch() throws -> GitBranch?
    func getBranches() throws -> [GitBranch]
    func lightweightStatusEntries() throws -> [GitStatusEntry]
    func lightweightStatusEntriesAsync() async throws -> [GitStatusEntry]
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
