import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 当前项目状态管理
/// 维护当前选中的项目、文件、项目是否存在等状态
@MainActor
class ProjectVM: ObservableObject, SuperLog {
    nonisolated static let emoji = "🎯"
    private let verbose = false

    // MARK: - Properties

    /// 当前选中的项目
    @Published private(set) var project: Project? = nil

    /// 当前选中的文件
    @Published private(set) var file: GitDiffFile? = nil

    /// 当前项目路径是否存在
    @Published private(set) var projectExists = true

    /// 仓库管理器
    private let repoManager: RepoManager

    // MARK: - Initialization

    init(project: Project?, repoManager: RepoManager) {
        self.repoManager = repoManager
        self.project = project

        self.checkIfProjectExists()

        if let project = project {
            let isGit = LibGit2.isGitRepository(at: project.path)
            project.updateIsGitRepoCacheSync(isGit)
        }
    }

    // MARK: - Project Management

    /// 设置当前项目
    /// - Parameters:
    ///   - p: 要设置的项目
    ///   - reason: 设置原因
    func setProject(_ p: Project?, reason: String) {
        if verbose {
            os_log("\(self.t)Set Project(\(reason)) \n ➡️ \(p?.path ?? "")")
        }

        self.project = p
        self.repoManager.stateRepo.setProjectPath(self.project?.path ?? "")
        self.checkIfProjectExists()

        if let project = p {
            let isGit = LibGit2.isGitRepository(at: project.path)
            project.updateIsGitRepoCacheSync(isGit)

            Task.detached(priority: .userInitiated) {
                await project.updateIsGitRepoCache()
            }
        }
    }

    /// 设置当前选中的文件
    /// - Parameter f: 要设置的文件
    func setFile(_ f: GitDiffFile?) {
        if f == self.file { return }
        file = f
    }

    // MARK: - Private

    private func checkIfProjectExists() {
        if let newProject = self.project {
            self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
        } else {
            self.projectExists = false
        }
    }
}
