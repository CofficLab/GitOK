import Foundation
import KitGit
import ProviderGit
import ProviderGitUser
import ProviderProjects

/// 工作区概览的自有状态模型。
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

    /// 当前项目未提交变更的条数（工作区状态提示用；无项目或未读取时为 0）。
    @Published private(set) var changeCount = 0

    /// 是否正在首次检查工作区状态。
    @Published private(set) var isLoading = false

    /// 当前是否选中了 commit。
    ///
    /// 概览只在「有项目 + 未选中 commit」时展示；把该状态存下来是为了让
    /// 后续 `handleDataChanged`（提交 / 推送 / 分支切换 / 外部编辑触发）触发的
    /// `reload` 也保持隐藏——否则已选 commit 后的一次 dataChanged 会因工作区
    /// 干净而重新亮起概览，盖住 commit 详情。
    @Published private(set) var hasSelectedCommit = false

    /// Git 用户预设列表，由 `GitUserPresetProviding` 通过插件级 Observer 驱动。
    @Published private(set) var userPresets: [GitUserPreset] = []

    /// 协作者列表，由 `CollaboratorProviding` 通过插件级 Observer 驱动。
    @Published private(set) var collaborators: [Collaborator] = []

    /// 当前项目仓库配置中的 Git 用户身份。
    @Published private(set) var currentUserName = ""
    @Published private(set) var currentUserEmail = ""
    @Published private(set) var isLoadingUserConfiguration = false
    @Published private(set) var isApplyingUserPreset = false

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
    private var userConfigurationToken = 0

    /// 外部项目 / 选中状态变化（打开 / 切换 / 关闭项目、选中 / 取消 commit）。
    ///
    /// 概览只在「有项目 + 未选中 commit」时展示，其余情况直接隐藏。
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
            changeCount = 0
            loadUserConfiguration(for: project)
            if isClean {
                isClean = false
            }
        }
        guard project != nil, !hasSelectedCommit else {
            loadToken &+= 1
            if isClean {
                isClean = false
            }
            changeCount = 0
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
    /// 选中 commit 后工作区数据变化不应重新点亮概览，因此这里同样
    /// 以 `!hasSelectedCommit` 为前提（与 `handleProjectChanged` 一致）。
    private func reload(force: Bool = false) {
        guard let project, !hasSelectedCommit else {
            loadToken &+= 1
            if isClean {
                isClean = false
            }
            changeCount = 0
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
        checkedProjectURL = project.url

        guard FileManager.default.fileExists(atPath: project.url.path) else {
            isClean = false
            changeCount = 0
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
        Task.detached(priority: .utility) {
            let result = Result {
                if let git {
                    return try git.loadStatus(in: url)
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
                    if didChange, self.changeCount != status.changeCount {
                        self.changeCount = status.changeCount
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
