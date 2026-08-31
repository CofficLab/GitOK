import GitOKAppCore
import Foundation
import KitGitCore
import KitGitOKCore
import ProviderProject

@MainActor
public final class GitOKProjectService: GitOKProjectServicing {
    private let dataVM: DataVM
    private let projectVM: ProjectVM

    public init(dataVM: DataVM, projectVM: ProjectVM) {
        self.dataVM = dataVM
        self.projectVM = projectVM
    }

    // MARK: - Snapshot state

    public var projectURL: URL? { projectVM.project?.url }
    public var projectPath: String? { projectVM.project?.path }
    public var projectTitle: String? { projectVM.project?.title }
    public var branchName: String? { dataVM.branch?.name }
    public var isGitRepository: Bool { projectVM.currentProjectIsGitRepository }
    public var selectedFilePath: String? { projectVM.file?.file }
    public var remoteTrackingStatus: GitOKRemoteTrackingStatus? {
        GitOKRemoteTrackingStatus(
            ahead: projectVM.aheadCount,
            behind: projectVM.behindCount,
            hasUpstream: projectVM.hasUpstream
        )
    }
    public var isClean: Bool { projectVM.isClean }
    public var unpushedCommitsCount: Int { projectVM.unpushedCommitsCount }
    public var projectExists: Bool { projectVM.projectExists }
    public var isCheckingGitRepository: Bool { projectVM.isCheckingCurrentProjectGitRepository }
    public var lastFetchedAt: Date? { projectVM.lastFetchedAt }

    // MARK: - Batch A read operations

    public func refreshGitRepositoryState(reason: String) {
        projectVM.refreshCurrentProjectGitRepositoryState(reason: reason)
    }

    public func refreshCurrentBranch(reason: String) {
        dataVM.refreshCurrentBranch(
            project: projectVM.project,
            isGitRepository: projectVM.currentProjectIsGitRepository,
            reason: reason
        )
    }

    public func getCurrentBranch() throws -> GitBranch? {
        try requireProject().getCurrentBranch()
    }

    public func getBranches() throws -> [GitBranch] {
        try requireProject().getBranches()
    }

    public func lightweightStatusEntries() throws -> [GitStatusEntry] {
        try requireProject().lightweightStatusEntries()
    }

    public func lightweightStatusEntriesAsync() async throws -> [GitStatusEntry] {
        try await requireProject().lightweightStatusEntriesAsync()
    }

    public func refreshStatus() async throws -> [GitStatusEntry] {
        try await lightweightStatusEntriesAsync()
    }

    public func hasStagedChangesAsync() async throws -> Bool {
        try await requireProject().hasStagedChangesAsync()
    }

    public func isGitAsync() async -> Bool {
        guard let project = projectVM.project else { return false }
        return await project.isGitAsync()
    }

    public func headCommitHashAsync() async -> String? {
        guard let project = projectVM.project else { return nil }
        return await project.headCommitHashAsync()
    }

    public func untrackedFiles() async throws -> [GitDiffFile] {
        try await requireProject().untrackedFiles()
    }

    public func stagedDiffFileList() async throws -> [GitDiffFile] {
        try await requireProject().stagedDiffFileList()
    }

    public func unstagedDiffFileList() async throws -> [GitDiffFile] {
        try await requireProject().unstagedDiffFileList()
    }

    public func getUnPushedCommitCountAsync() async throws -> Int {
        try await requireProject().getUnPushedCommitCountAsync()
    }

    public func aheadBehind() throws -> GitAheadBehind {
        try requireProject().aheadBehind()
    }

    public func aheadBehindAsync() async throws -> GitAheadBehind {
        try await requireProject().aheadBehindAsync()
    }

    // MARK: - Private

    private func requireProject() throws -> Project {
        guard let project = projectVM.project else {
            throw GitOKProjectServiceError.noCurrentProject
        }
        return project
    }
}
