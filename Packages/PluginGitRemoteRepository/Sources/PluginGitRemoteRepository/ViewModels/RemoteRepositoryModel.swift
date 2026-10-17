import Foundation
import KitGit
import Observation
import ProviderGit

/// 远程仓库面板所需的最小 Git 能力边界。
///
/// 只声明面板实际使用的 3 个成员，`any GitProviding` 在入口处收窄为该协议；
/// 模型因此可在测试中用极小替身驱动，无需实现 `GitProviding` 的全部方法。
///
/// 与 `GitProviding` 保持一致为非隔离 `Sendable`：这些方法在后台任务中调用。
protocol RemoteRepositoryGitCapability: Sendable {
    func listRemotes(in repository: URL) -> [GitRemoteSummary]
    func addRemote(name: String, url: String, in repository: URL) throws
    func removeRemote(name: String, in repository: URL) throws
}

/// 将 `any GitProviding` 收窄为远程仓库面板所需的能力。
struct RemoteRepositoryGitCapabilityAdapter: RemoteRepositoryGitCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        git.listRemotes(in: repository)
    }

    func addRemote(name: String, url: String, in repository: URL) throws {
        try git.addRemote(name: name, url: url, in: repository)
    }

    func removeRemote(name: String, in repository: URL) throws {
        try git.removeRemote(name: name, in: repository)
    }
}

/// 远程仓库管理面板的状态机：加载列表、添加、删除。
///
/// 原先这些逻辑内嵌在 `RemoteRepositoryView` 的 `@State` + `Task.detached` 中，
/// 无法单测；此处抽为可注入依赖的模型，View 只负责渲染与转发用户操作。
@MainActor
@Observable
final class RemoteRepositoryModel {
    // MARK: - 状态

    /// 已加载的远程列表。
    private(set) var remotes: [GitRemoteSummary] = []

    /// 是否仍在加载列表。
    private(set) var isLoading = true

    /// 最近一次失败提示；`nil` 表示无错误。
    private(set) var errorMessage: String?

    /// 是否有操作正在进行（用于禁用按钮）。
    private(set) var isPerformingAction = false

    // MARK: - 依赖

    private let git: any RemoteRepositoryGitCapability
    /// 当前仓库根目录；`nil` 表示没有选中项目。
    private let repositoryURL: () -> URL?

    init(git: any RemoteRepositoryGitCapability, repositoryURL: @escaping () -> URL?) {
        self.git = git
        self.repositoryURL = repositoryURL
    }

    // MARK: - 加载

    /// 重新加载远程列表。
    ///
    /// 无选中项目时清空列表并结束加载态；否则在后台读取，
    /// 只有最新世代的结果才写回。
    func load() {
        generation &+= 1
        let generation = self.generation
        loadTask?.cancel()

        guard let url = repositoryURL() else {
            remotes = []
            isLoading = false
            return
        }

        isLoading = true
        let git = self.git
        loadTask = Task.detached(priority: .userInitiated) {
            let loaded = git.listRemotes(in: url)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self, generation == self.generation else { return }
                self.remotes = loaded
                self.isLoading = false
                self.loadTask = nil
            }
        }
    }

    // MARK: - 添加

    /// 添加一个远程仓库，成功后刷新列表。
    func addRemote(name: String, url: String) {
        guard let repositoryURL = repositoryURL() else { return }

        beginAction()
        let generation = self.generation
        let git = self.git
        actionTask = Task.detached(priority: .userInitiated) {
            do {
                try git.addRemote(name: name, url: url, in: repositoryURL)
                let loaded = git.listRemotes(in: repositoryURL)
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.remotes = loaded
                    self.errorMessage = nil
                    self.isPerformingAction = false
                    self.actionTask = nil
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.errorMessage = error.localizedDescription
                    self.isPerformingAction = false
                    self.actionTask = nil
                }
            }
        }
    }

    // MARK: - 删除

    /// 删除一个远程仓库，成功后刷新列表。
    func deleteRemote(_ remote: GitRemoteSummary) {
        guard let repositoryURL = repositoryURL() else { return }

        beginAction()
        let generation = self.generation
        let git = self.git
        actionTask = Task.detached(priority: .userInitiated) {
            do {
                try git.removeRemote(name: remote.name, in: repositoryURL)
                let loaded = git.listRemotes(in: repositoryURL)
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.remotes = loaded
                    self.errorMessage = nil
                    self.isPerformingAction = false
                    self.actionTask = nil
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.errorMessage = error.localizedDescription
                    self.isPerformingAction = false
                    self.actionTask = nil
                }
            }
        }
    }

    /// 丢弃当前错误提示。
    func dismissError() {
        errorMessage = nil
    }

    // MARK: - 私有

    /// 发起操作时的世代号；每次操作自增，用于丢弃过期结果。
    private var generation = 0
    /// 进行中的操作任务。
    private var actionTask: Task<Void, Never>?
    /// 进行中的列表加载任务。
    private var loadTask: Task<Void, Never>?

    /// 进入忙碌态：世代自增、取消上一个操作、清空旧错误。
    private func beginAction() {
        generation &+= 1
        actionTask?.cancel()
        isPerformingAction = true
        errorMessage = nil
    }
}
