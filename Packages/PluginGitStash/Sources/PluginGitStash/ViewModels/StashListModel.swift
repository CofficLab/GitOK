import Foundation
import KitGit
import Observation
import ProviderGit

/// stash 面板所需的最小 Git 能力边界。
///
/// 只声明面板实际使用的 6 个成员，`any GitProviding` 在入口处收窄为该协议；
/// 模型因此可在测试中用极小替身驱动，无需实现 `GitProviding` 的全部方法。
///
/// 与 `GitProviding` 保持一致为非隔离 `Sendable`：这些方法在后台任务中调用。
protocol StashGitCapability: Sendable {
    func listStashes(in repository: URL) -> [GitStashEntry]
    func hasChangesToStash(in repository: URL) -> Bool
    func saveStash(message: String?, in repository: URL) throws
    func applyStash(_ entry: GitStashEntry, in repository: URL) throws
    func popStash(_ entry: GitStashEntry, in repository: URL) throws
    func dropStash(_ entry: GitStashEntry, in repository: URL) throws
}

/// 将 `any GitProviding` 收窄为 stash 面板所需的能力。
struct StashGitCapabilityAdapter: StashGitCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func listStashes(in repository: URL) -> [GitStashEntry] {
        git.listStashes(in: repository)
    }

    func hasChangesToStash(in repository: URL) -> Bool {
        git.hasChangesToStash(in: repository)
    }

    func saveStash(message: String?, in repository: URL) throws {
        try git.saveStash(message: message, in: repository)
    }

    func applyStash(_ entry: GitStashEntry, in repository: URL) throws {
        try git.applyStash(entry, in: repository)
    }

    func popStash(_ entry: GitStashEntry, in repository: URL) throws {
        try git.popStash(entry, in: repository)
    }

    func dropStash(_ entry: GitStashEntry, in repository: URL) throws {
        try git.dropStash(entry, in: repository)
    }
}

/// Stash 面板的操作结果消息，供 View 直接渲染。
enum StashPanelMessage: Equatable {
    /// 操作成功的绿色提示。
    case success(String)
    /// 操作失败的橙色提示（可复制，便于用户反馈错误详情）。
    case failure(String)
}

/// Stash 面板的完整状态机：列表加载、保存、apply / pop / drop。
///
/// 原先这些逻辑内嵌在 `StashListView` 的 `@State` + `Task.detached` 中，
/// 无法单测；此处抽为可注入依赖的模型，View 只负责渲染与转发用户操作。
///
/// 并发语义与原实现一致：每个操作都记下发起时的世代号，
/// 只有仍是最新世代的操作才允许写回状态，避免慢请求覆盖新结果。
@MainActor
@Observable
final class StashListModel {
    /// 面板可执行的操作。
    enum Action: Equatable {
        case apply(GitStashEntry)
        case pop(GitStashEntry)
        case drop(GitStashEntry)
    }

    // MARK: - 状态

    /// 已加载的 stash 列表。
    private(set) var stashes: [GitStashEntry] = []

    /// 是否仍在加载列表。
    private(set) var isLoading = true

    /// 是否有操作正在进行（用于禁用按钮并显示进度条）。
    private(set) var isPerformingAction = false

    /// 最近一次操作结果消息；`nil` 表示无消息。
    private(set) var message: StashPanelMessage?

    /// 保存输入框中的 stash 消息。
    var stashMessage: String = ""

    // MARK: - 依赖

    private let git: any StashGitCapability
    /// 当前仓库根目录；`nil` 表示没有选中项目。
    private let repositoryURL: () -> URL?
    /// stash 变化后通知外部刷新（如状态栏计数）。
    private let onStashesChanged: () -> Void
    /// 本地化文案来源，注入后测试无需依赖 bundle 资源。
    private let strings: StashPanelStrings

    /// 面板文案集合。
    struct StashPanelStrings: Equatable {
        var noChangesToStash: String
        var stashSaved: String

        init(
            noChangesToStash: String = GitStashLocalization.string("No changes to stash", bundle: .module),
            stashSaved: String = GitStashLocalization.string("Stash saved", bundle: .module)
        ) {
            self.noChangesToStash = noChangesToStash
            self.stashSaved = stashSaved
        }
    }

    /// 发起操作时的世代号；每次操作自增，用于丢弃过期结果。
    private var generation = 0
    /// 进行中的操作任务，取消时用于提前退出。
    private var actionTask: Task<Void, Never>?
    /// 进行中的列表加载任务。
    private var loadTask: Task<Void, Never>?

    init(
        git: any StashGitCapability,
        repositoryURL: @escaping () -> URL?,
        onStashesChanged: @escaping () -> Void = {},
        strings: StashPanelStrings = StashPanelStrings()
    ) {
        self.git = git
        self.repositoryURL = repositoryURL
        self.onStashesChanged = onStashesChanged
        self.strings = strings
    }

    // MARK: - 加载

    /// 重新加载 stash 列表。
    ///
    /// 无选中项目时清空列表并结束加载态；否则在后台读取，
    /// 只有最新世代的结果才写回。
    func load() {
        loadGenerationTick()
        let generation = self.generation
        loadTask?.cancel()

        guard let url = repositoryURL() else {
            stashes = []
            isLoading = false
            return
        }

        isLoading = true
        let git = self.git
        loadTask = Task.detached(priority: .userInitiated) {
            let loaded = git.listStashes(in: url)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self, generation == self.generation else { return }
                self.stashes = loaded
                self.isLoading = false
                self.loadTask = nil
            }
        }
    }

    // MARK: - 保存

    /// 保存当前输入的 stash 消息。
    ///
    /// 无项目时直接返回；无改动时不发起操作并提示；
    /// 空消息按 `nil` 传给 Git（使用默认消息）。
    func save() {
        guard let url = repositoryURL() else { return }

        let trimmed = stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard git.hasChangesToStash(in: url) else {
            message = .failure(strings.noChangesToStash)
            return
        }

        beginAction()
        let generation = self.generation
        let git = self.git
        actionTask = Task.detached(priority: .userInitiated) {
            do {
                try git.saveStash(message: trimmed.isEmpty ? nil : trimmed, in: url)
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.stashMessage = ""
                    self.isPerformingAction = false
                    self.actionTask = nil
                    self.message = .success(self.strings.stashSaved)
                    self.onStashesChanged()
                    self.load()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.isPerformingAction = false
                    self.actionTask = nil
                    self.message = .failure(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 条目操作

    /// 对某个 stash 执行 apply / pop / drop。
    func perform(_ action: Action) {
        guard let url = repositoryURL() else { return }

        beginAction()
        let generation = self.generation
        let git = self.git
        actionTask = Task.detached(priority: .userInitiated) {
            do {
                switch action {
                case .apply(let entry):
                    try git.applyStash(entry, in: url)
                case .pop(let entry):
                    try git.popStash(entry, in: url)
                case .drop(let entry):
                    try git.dropStash(entry, in: url)
                }
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.isPerformingAction = false
                    self.actionTask = nil
                    self.onStashesChanged()
                    self.load()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.isPerformingAction = false
                    self.actionTask = nil
                    self.message = .failure(error.localizedDescription)
                }
            }
        }
    }

    /// 丢弃当前消息提示。
    func dismissMessage() {
        message = nil
    }

    // MARK: - 私有

    /// 进入忙碌态：世代自增、取消上一个操作、清空旧消息。
    private func beginAction() {
        generation &+= 1
        actionTask?.cancel()
        isPerformingAction = true
        message = nil
    }

    /// 世代自增（列表加载使用，不进入忙碌态）。
    private func loadGenerationTick() {
        generation &+= 1
    }
}
