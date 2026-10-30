import Foundation
import KitGit
import ProviderGit
import ProviderGitUser
import ProviderProjects

/// 工作区干净视图的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`WorktreeCleanObserver` 把外部
/// （Provider / GitRepositoryWatching）事件翻译成本模型的领域方法。
/// 视图只绑定本模型，不再直接读取 Provider 或监听系统通知。
@MainActor
final class WorktreeCleanViewModel: ObservableObject {
    private let git: (any GitProviding)?
    private let fallbackStatusLoader: (@Sendable (URL) throws -> GitWorktreeStatus)?
    private let ensureUserPreset: ((String, String) -> Void)?

    init(
        git: (any GitProviding)? = nil,
        ensureUserPreset: ((String, String) -> Void)? = nil,
        fallbackStatusLoader: (@Sendable (URL) throws -> GitWorktreeStatus)? = nil
    ) {
        self.git = git
        self.ensureUserPreset = ensureUserPreset
        self.fallbackStatusLoader = fallbackStatusLoader
    }

    /// 当前项目；未打开项目时为 nil。
    @Published private(set) var project: Project?

    /// 当前项目工作区是否干净（无未提交变更）。
    @Published private(set) var isClean = false

    /// 工作区内容归属（变更列表 / 干净概览 / 待定）。
    ///
    /// 由 Provider 统一广播：干净概览与变更列表必须使用同一份判定，否则两块
    /// 内容同时「不占布局」会让主内容区整块塌陷（提交表单漂到面板中间）。
    @Published private(set) var worktreeOwner: WorktreeContentOwner = .pending

    /// 干净概览是否应该展示。
    ///
    /// 需要同时满足：工作区确认干净、未选中 commit、已打开项目。
    /// 归属判定本身与 commit 选择无关，因此选中 commit 时归属保持不变，
    /// 只由本属性决定干净概览是否让位给 commit 详情。
    var showsCleanState: Bool {
        worktreeOwner == .clean && !hasSelectedCommit && project != nil
    }

    /// 是否正在首次检查工作区状态。
    @Published private(set) var isLoading = false

    /// 工作区内容归属变化（Provider 广播）。
    ///
    /// 与变更列表共用同一份判定：任何时刻两边的结论一致，
    /// 不会同时「不占布局」把主内容区掏空。
    func handleWorktreeOwnerChanged(_ owner: WorktreeContentOwner) {
        guard worktreeOwner != owner else { return }
        worktreeOwner = owner
    }

    /// 当前是否选中了 commit。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示；把该状态存下来是为了让
    /// 后续 `handleDataChanged`（提交 / 推送 / 分支切换 / 外部编辑触发）触发的
    /// `reload` 也保持隐藏——否则已选 commit 后的一次 dataChanged 会因工作区
    /// 干净而重新亮起干净视图，盖住 commit 详情。
    private var hasSelectedCommit = false

    /// Git 用户预设列表，由 `GitUserPresetProviding` 通过插件级 Observer 驱动。
    @Published private(set) var userPresets: [GitUserPreset] = []

    /// 协作者列表，由 `CollaboratorProviding` 通过插件级 Observer 驱动。
    @Published private(set) var collaborators: [Collaborator] = []

    /// 当前项目仓库配置中的 Git 用户身份。
    @Published private(set) var currentUserName = ""
    @Published private(set) var currentUserEmail = ""
    @Published private(set) var isLoadingUserConfiguration = false
    @Published private(set) var isApplyingUserPreset = false

    /// 仓库 HEAD 或 refs 变化时递增，供仓库信息视图刷新分支、标签和提交元数据。
    @Published private(set) var repositoryInfoRevision = 0

    /// 已检查过工作区状态的项目 URL（用于避免对同一项目重复加载）。
    private var checkedProjectURL: URL?

    /// 最近一次成功读取的工作区快照。
    ///
    /// 文件监听会报告所有工作区文件变化，其中一部分不会改变 Git 状态
    /// （例如被忽略的文件，或文件很快恢复原状）。保留快照后，这类事件只
    /// 触发后台检查，不会重复更新 SwiftUI 状态。
    private var lastStatus: GitWorktreeStatus?

    /// 加载序号：只接受最后一次检查结果，避免旧任务覆盖新快照。
    private var loadToken = 0
    private var statusCancellation: GitProcessCancellation?
    private var userConfigurationToken = 0

    /// 外部项目 / 选中状态变化（打开 / 切换 / 关闭项目、选中 / 取消 commit）。
    ///
    /// 干净视图只在「有项目 + 未选中 commit」时展示，其余情况直接隐藏。
    func handleProjectChanged(project: Project?, hasSelectedCommit: Bool) {
        let previousProjectURL = self.project?.url
        let previousHasSelectedCommit = self.hasSelectedCommit
        if self.project != project {
            self.project = project
        }
        self.hasSelectedCommit = hasSelectedCommit
        let projectChanged = previousProjectURL != project?.url
        if projectChanged {
            checkedProjectURL = nil
            lastStatus = nil
            loadUserConfiguration(for: project)
            if isClean {
                isClean = false
            }
            // 切换项目时归属回到该仓库当前结论：预热插件可能已经扫过这个仓库，
            // 直接沿用它的判定，避免明明有结论却先闪一帧「待定」。
            if let git, let url = project?.url {
                worktreeOwner = git.worktreeContentOwner(for: url)
            } else {
                worktreeOwner = .pending
            }
        }
        guard project != nil, !hasSelectedCommit else {
            loadToken &+= 1
            statusCancellation?.cancel()
            statusCancellation = nil
            if isClean {
                isClean = false
            }
            if isLoading {
                isLoading = false
            }
            checkedProjectURL = nil
            lastStatus = nil
            userConfigurationToken &+= 1
            currentUserName = ""
            currentUserEmail = ""
            isLoadingUserConfiguration = false
            return
        }
        let selectionChanged = previousHasSelectedCommit != hasSelectedCommit
        if !projectChanged, selectionChanged, !hasSelectedCommit {
            loadUserConfiguration(for: project)
        }
        reload(force: projectChanged || selectionChanged)
    }

    /// 外部仓库 / 工作区数据变化（提交 / 推送 / 分支切换 / 外部编辑文件）。
    ///
    /// 提交、外部把工作区改干净后，干净状态需要据此重新判定。
    func handleDataChanged() {
        reload(force: true)
        // 工作区变化不会改变仓库级 Git 用户身份。不要在每次文件事件
        // 中重新读取配置并切换 isLoadingUserConfiguration，否则用户名、
        // 预设和协作者区域会随着文件监听事件反复闪烁。
    }

    /// 仓库元数据发生变化时通知仍在显示的仓库信息视图重新读取。
    func handleRepositoryInfoChanged() {
        repositoryInfoRevision &+= 1
    }

    /// 外部预设 Provider 发生变化后，由插件级 Observer 推送最新快照。
    func handleUserPresetsChanged(_ presets: [GitUserPreset]) {
        userPresets = presets
    }

    /// 外部协作者 Provider 发生变化后，由插件级 Observer 推送最新快照。
    func handleCollaboratorsChanged(_ collaborators: [Collaborator]) {
        self.collaborators = collaborators
    }

    /// 将选中的预设应用到当前项目仓库，并同步当前身份展示。
    func applyUserPreset(_ preset: GitUserPreset) {
        guard let project, !hasSelectedCommit else { return }
        let url = project.url
        isApplyingUserPreset = true

        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", preset.name, in: url)
                try GitConfigReader.setValue("user.email", preset.email, in: url)
                await MainActor.run {
                    self.isApplyingUserPreset = false
                    guard self.project?.url == url else { return }
                    self.currentUserName = preset.name
                    self.currentUserEmail = preset.email
                }
            } catch {
                await MainActor.run {
                    self.isApplyingUserPreset = false
                }
            }
        }
    }

    /// 将选中的协作者应用到当前项目仓库，并同步当前身份展示。
    func applyCollaborator(_ collaborator: Collaborator) {
        guard let project, !hasSelectedCommit else { return }
        let url = project.url
        isApplyingUserPreset = true

        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", collaborator.name, in: url)
                try GitConfigReader.setValue("user.email", collaborator.email, in: url)
                await MainActor.run {
                    self.isApplyingUserPreset = false
                    guard self.project?.url == url else { return }
                    self.currentUserName = collaborator.name
                    self.currentUserEmail = collaborator.email
                }
            } catch {
                await MainActor.run {
                    self.isApplyingUserPreset = false
                }
            }
        }
    }

    // MARK: - Private

    private func loadUserConfiguration(for project: Project?, clearBeforeLoad: Bool = true) {
        userConfigurationToken &+= 1
        let token = userConfigurationToken

        guard let project else {
            currentUserName = ""
            currentUserEmail = ""
            isLoadingUserConfiguration = false
            return
        }

        if clearBeforeLoad {
            currentUserName = ""
            currentUserEmail = ""
        }
        isLoadingUserConfiguration = true
        let url = project.url

        Task.detached(priority: .utility) {
            let config = GitConfigReader.user(in: url)
            await MainActor.run {
                guard token == self.userConfigurationToken,
                      self.project?.url == url else { return }
                self.currentUserName = config.name ?? ""
                self.currentUserEmail = config.email ?? ""
                self.isLoadingUserConfiguration = false
                if !self.currentUserName.isEmpty, !self.currentUserEmail.isEmpty {
                    self.ensureUserPreset?(self.currentUserName, self.currentUserEmail)
                }
            }
        }
    }

    /// 重新检查当前项目工作区是否干净。
    ///
    /// 选中 commit 后工作区数据变化不应重新点亮干净视图，因此这里同样
    /// 以 `!hasSelectedCommit` 为前提（与 `handleProjectChanged` 一致）。
    private func reload(force: Bool = false) {
        guard let project, !hasSelectedCommit else {
            loadToken &+= 1
            statusCancellation?.cancel()
            statusCancellation = nil
            if isClean {
                isClean = false
            }
            if isLoading {
                isLoading = false
            }
            checkedProjectURL = nil
            lastStatus = nil
            return
        }
        if checkedProjectURL == project.url && lastStatus != nil && !force { return }

        loadToken &+= 1
        let token = loadToken
        statusCancellation?.cancel()
        statusCancellation = nil
        checkedProjectURL = project.url

        guard FileManager.default.fileExists(atPath: project.url.path) else {
            statusCancellation?.cancel()
            statusCancellation = nil
            isClean = false
            isLoading = false
            lastStatus = nil
            return
        }

        // 与 commitlist 保留已有列表的策略一致：已有快照时保持当前页面稳定，
        // 不因为一次后台校验而切换加载态。首次加载仍显示 loading 状态。
        if lastStatus == nil {
            isLoading = true
        }

        let url = project.url
        let git = self.git
        let fallbackStatusLoader = self.fallbackStatusLoader
        let cancellation = git.map { _ in GitProcessCancellation(forceKillAfter: 1) }
        statusCancellation = cancellation
        Task.detached(priority: .utility) {
            let result = Result {
                if let git {
                    return try git.loadStatus(in: url, cancellation: cancellation)
                }
                if let fallbackStatusLoader {
                    return try fallbackStatusLoader(url)
                }
                throw GitProviderError.noBackendAvailable
            }
            await MainActor.run {
                // 仅当仍指向同一项目、且仍未选中 commit 时应用结果，
                // 且只接受最后一次检查结果，避免切换项目或连续事件造成旧状态覆盖。
                guard token == self.loadToken,
                      self.project?.url == url,
                      !self.hasSelectedCommit else { return }

                self.statusCancellation = nil
                switch result {
                case .success(let status):
                    let didChange = WorktreeCleanRefreshPolicy.didChange(
                        previous: self.lastStatus,
                        current: status
                    )
                    self.lastStatus = status
                    if didChange, self.isClean != status.isClean {
                        self.isClean = status.isClean
                    }
                    // 归属方统一取自 Provider：干净概览与变更列表共用同一份判定，
                    // 两块内容不会同时「不占布局」把主内容区塌陷掉。
                    if let git {
                        self.worktreeOwner = git.worktreeContentOwner(for: url)
                    } else {
                        self.worktreeOwner = status.isClean ? .clean : .changes
                    }
                    if self.isLoading {
                        self.isLoading = false
                    }
                case .failure:
                    // 检查失败时保留已有状态，避免一次瞬时 git 错误把页面
                    // 错误地切换成「干净」或「有变更」。首次检查则结束 loading。
                    if self.isLoading {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

/// 工作区刷新时的纯数据判断，供 ViewModel 和测试复用。
enum WorktreeCleanRefreshPolicy {
    static func didChange(previous: GitWorktreeStatus?, current: GitWorktreeStatus) -> Bool {
        previous != current
    }
}
