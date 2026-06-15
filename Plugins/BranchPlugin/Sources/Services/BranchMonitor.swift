import Foundation
import Observation

/// Monitors the HEAD file of a Git repository to track the current branch.
///
/// Uses kernel-level file system events (via `DispatchSource`) for efficient,
/// low-latency updates. Supports both regular repositories and worktrees
/// (where `.git` is a file pointing to the actual git directory).
@Observable
@MainActor
final class BranchMonitor {

    // MARK: - Public State

    /// The current branch name, an abbreviated commit hash for detached HEAD,
    /// or `nil` if the repository has no HEAD or is not a git repository.
    private(set) var branchName: String?

    // MARK: - Private State

    private let projectURL: URL
    private let isGitRepository: Bool
    private var dispatchSource: DispatchSourceFileSystemObject?

    // MARK: - Init

    init(projectURL: URL?, isGitRepository: Bool) {
        self.projectURL = projectURL ?? URL(fileURLWithPath: "/")
        self.isGitRepository = isGitRepository
        self.branchName = nil

        if isGitRepository, projectURL != nil {
            startMonitoring()
        }
    }

    // MARK: - Public API

    /// Re-read the current branch and restart file monitoring.
    func refresh() {
        stopMonitoring()
        if isGitRepository {
            startMonitoring()
        }
    }

    // MARK: - File Monitoring

    /// Resolves the HEAD file URL, handling worktrees.
    ///
    /// In a worktree, `.git` is a file containing `gitdir: <path>`.
    /// In a normal repository, `.git` is a directory containing `HEAD`.
    private var headFileURL: URL? {
        guard isGitRepository else { return nil }
        return resolveGitHeadURL()
    }

    private func resolveGitHeadURL() -> URL {
        let gitPath = projectURL.appendingPathComponent(".git")

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: gitPath.path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                // .git is a file — worktree case
                // Content format: "gitdir: /path/to/.git/worktrees/<name>"
                if let content = try? String(contentsOf: gitPath, encoding: .utf8),
                   content.hasPrefix("gitdir: ") {
                    let gitDirPath = String(content.dropFirst("gitdir: ".count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let gitDirURL = URL(fileURLWithPath: gitDirPath)
                    return gitDirURL.appendingPathComponent("HEAD")
                }
            }
        }

        // Normal repository
        return gitPath.appendingPathComponent("HEAD")
    }

    private func startMonitoring() {
        // Read current branch synchronously first
        readCurrentBranch()

        // Set up file system event monitoring
        guard let headURL = headFileURL else { return }

        let fd = open(headURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.readCurrentBranch()
        }

        // The cancel handler owns the fd and closes it when the source is cancelled
        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        dispatchSource = source
    }

    private func stopMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    private func readCurrentBranch() {
        guard let headURL = headFileURL else {
            branchName = nil
            return
        }

        guard let content = try? String(contentsOf: headURL, encoding: .utf8) else {
            branchName = nil
            return
        }
        
        branchName = Self.parseBranchName(from: content)
    }

    // MARK: - Parsing

    /// Parses a branch name from HEAD file content.
    ///
    /// - Parameter content: Raw content of the HEAD file
    /// - Returns: Branch name, abbreviated commit hash for detached HEAD, or `nil`
    static func parseBranchName(from content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("ref: ") {
            // Normal branch: "ref: refs/heads/main"
            let ref = String(trimmed.dropFirst(5))
            if ref.hasPrefix("refs/heads/") {
                return String(ref.dropFirst("refs/heads/".count))
            }
            // Non-standard ref path
            return ref
        }

        // Detached HEAD — a commit hash (40 hex for SHA-1, 64 for SHA-256)
        if trimmed.count == 40 || trimmed.count == 64,
           trimmed.allSatisfy({ $0.isHexDigit }) {
            return String(trimmed.prefix(7))
        }

        return nil
    }
}
