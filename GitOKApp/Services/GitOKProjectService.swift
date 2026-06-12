import GitOKAppCore
import Foundation
import GitCoreKit
import GitOKCoreKit
import ProjectKit

@MainActor
final class GitOKProjectService: GitOKProjectServicing {
    private let dataVM: DataVM
    private let projectVM: ProjectVM

    init(dataVM: DataVM, projectVM: ProjectVM) {
        self.dataVM = dataVM
        self.projectVM = projectVM
    }

    // MARK: - Snapshot state

    var projectURL: URL? { projectVM.project?.url }
    var projectPath: String? { projectVM.project?.path }
    var projectTitle: String? { projectVM.project?.title }
    var branchName: String? { dataVM.branch?.name }
    var isGitRepository: Bool { projectVM.currentProjectIsGitRepository }
    var selectedFilePath: String? { projectVM.file?.file }
    var remoteTrackingStatus: GitOKRemoteTrackingStatus? {
        GitOKRemoteTrackingStatus(
            ahead: projectVM.aheadCount,
            behind: projectVM.behindCount,
            hasUpstream: projectVM.hasUpstream
        )
    }
    var isClean: Bool { projectVM.isClean }
    var unpushedCommitsCount: Int { projectVM.unpushedCommitsCount }
    var projectExists: Bool { projectVM.projectExists }
    var isCheckingGitRepository: Bool { projectVM.isCheckingCurrentProjectGitRepository }
    var lastFetchedAt: Date? { projectVM.lastFetchedAt }

    // MARK: - Batch A read operations

    func refreshGitRepositoryState(reason: String) {
        projectVM.refreshCurrentProjectGitRepositoryState(reason: reason)
    }

    func refreshCurrentBranch(reason: String) {
        dataVM.refreshCurrentBranch(
            project: projectVM.project,
            isGitRepository: projectVM.currentProjectIsGitRepository,
            reason: reason
        )
    }

    func getCurrentBranch() throws -> GitBranch? {
        try requireProject().getCurrentBranch()
    }

    func getBranches() throws -> [GitBranch] {
        try requireProject().getBranches()
    }

    func lightweightStatusEntries() throws -> [GitStatusEntry] {
        try requireProject().lightweightStatusEntries()
    }

    func lightweightStatusEntriesAsync() async throws -> [GitStatusEntry] {
        try await requireProject().lightweightStatusEntriesAsync()
    }

    func refreshStatus() async throws -> [GitStatusEntry] {
        try await lightweightStatusEntriesAsync()
    }

    func hasStagedChangesAsync() async throws -> Bool {
        try await requireProject().hasStagedChangesAsync()
    }

    func isGitAsync() async -> Bool {
        guard let project = projectVM.project else { return false }
        return await project.isGitAsync()
    }

    func headCommitHashAsync() async -> String? {
        guard let project = projectVM.project else { return nil }
        return await project.headCommitHashAsync()
    }

    func untrackedFiles() async throws -> [GitDiffFile] {
        try await requireProject().untrackedFiles()
    }

    func stagedDiffFileList() async throws -> [GitDiffFile] {
        try await requireProject().stagedDiffFileList()
    }

    func unstagedDiffFileList() async throws -> [GitDiffFile] {
        try await requireProject().unstagedDiffFileList()
    }

    func getUnPushedCommitCountAsync() async throws -> Int {
        try await requireProject().getUnPushedCommitCountAsync()
    }

    func aheadBehind() throws -> GitAheadBehind {
        try requireProject().aheadBehind()
    }

    func aheadBehindAsync() async throws -> GitAheadBehind {
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
