import Foundation

/// 插件视图构建上下文
///
/// `GitOKPluginContext` 是内核向插件视图方法注入数据的唯一通道。
/// 所有插件视图方法（toolbar、statusBar、list 等）都接收此上下文，
/// 从中读取需要的运行时状态，无需依赖 SwiftUI Environment 或全局单例。
///
/// ## 架构角色
///
/// ```text
/// ┌──────────────┐     GitOKPluginContext     ┌─────────────────┐
/// │  PluginVM    │ ───────────────────────── │  Plugin 视图方法  │
/// │  (内核侧)    │   包含全部运行时状态        │  (插件侧)        │
/// └──────────────┘                            └─────────────────┘
/// ```
///
/// ## 扩展指南
///
/// 当需要向插件传递更多上下文信息时，在此结构体中添加新属性即可。
/// 所有新增属性应提供合理的默认值，以保持向后兼容性。
@MainActor
public struct GitOKPluginContext {
    public let dependencies: GitOKPluginDependencies

    // MARK: - 项目信息

    /// 当前项目 URL
    public let projectURL: URL?

    /// 当前项目路径
    public let projectPath: String?

    /// 当前项目标题
    public let projectTitle: String?

    /// 当前分支名称
    public let branchName: String?

    /// 当前是否为 Git 仓库
    public let isGitRepository: Bool

    /// 当前选中的文件路径
    public let selectedFilePath: String?

    // MARK: - 远程跟踪

    /// 远程跟踪状态（ahead/behind 数量）
    public let remoteTrackingStatus: GitOKRemoteTrackingStatus?

    /// 项目列表（用于项目选择器）
    public let projects: [GitOKProjectSummary]

    /// 当前选中的项目 URL
    public let selectedProjectURL: URL?

    /// 侧边栏是否可见
    public let isSidebarVisible: Bool

    // MARK: - 活动状态

    /// 当前长运行任务的描述文本
    ///
    /// 当应用正在执行 git 操作（如 clone、push、pull 等）时，
    /// 内核会设置此值以展示进度状态。
    /// 为 `nil` 表示当前无活动任务。
    public let activityStatus: String?

    /// 当前上下文是否提供导入仓库所需的 App 桥接能力
    public let canImportRepository: Bool

    // MARK: - 操作回调

    /// 项目选择回调（用于项目选择器）
    public let onProjectSelection: GitOKProjectSelectionHandler

    /// 项目是否已存在回调（用于仓库导入目标校验）
    public let onProjectExists: GitOKProjectExistenceHandler

    /// 仓库导入完成后注册并选中项目的回调
    public let onRepositoryImported: GitOKRepositoryImportCompletionHandler

    /// 活动状态更新回调
    public let onActivityStatusUpdate: GitOKActivityStatusUpdateHandler

    /// 用户提示消息回调
    public let onInfoMessage: GitOKUserMessageHandler

    /// 主题选择回调
    public let onThemeSelection: GitOKThemeSelectionHandler

    /// 工作区清洁状态更新回调
    public let onCleanStatusUpdate: GitOKCleanStatusUpdateHandler

    /// Git 目录变更回调
    public let onGitDirectoryChange: GitOKGitDirectoryChangeHandler

    /// 未推送提交数量更新回调
    public let onUnpushedCommitsUpdate: GitOKUnpushedCommitsUpdateHandler

    /// 远程跟踪状态更新回调
    public let onRemoteTrackingUpdate: GitOKRemoteTrackingUpdateHandler

    public init(
        dependencies: GitOKPluginDependencies = GitOKPluginDependencies(),
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false,
        selectedFilePath: String? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        activityStatus: String? = nil,
        canImportRepository: Bool = false,
        onProjectSelection: @escaping GitOKProjectSelectionHandler = { _ in },
        onProjectExists: @escaping GitOKProjectExistenceHandler = { _ in false },
        onRepositoryImported: @escaping GitOKRepositoryImportCompletionHandler = { _ in false },
        onActivityStatusUpdate: @escaping GitOKActivityStatusUpdateHandler = { _ in },
        onInfoMessage: @escaping GitOKUserMessageHandler = { _ in },
        onThemeSelection: @escaping GitOKThemeSelectionHandler = { _ in },
        onCleanStatusUpdate: @escaping GitOKCleanStatusUpdateHandler = { _ in },
        onGitDirectoryChange: @escaping GitOKGitDirectoryChangeHandler = { _ in },
        onUnpushedCommitsUpdate: @escaping GitOKUnpushedCommitsUpdateHandler = { _, _ in },
        onRemoteTrackingUpdate: @escaping GitOKRemoteTrackingUpdateHandler = { _, _ in }
    ) {
        self.dependencies = dependencies
        self.projectURL = projectURL
        self.projectPath = projectPath
        self.projectTitle = projectTitle
        self.branchName = branchName
        self.isGitRepository = isGitRepository
        self.selectedFilePath = selectedFilePath
        self.remoteTrackingStatus = remoteTrackingStatus
        self.projects = projects
        self.selectedProjectURL = selectedProjectURL
        self.isSidebarVisible = isSidebarVisible
        self.activityStatus = activityStatus
        self.canImportRepository = canImportRepository
        self.onProjectSelection = onProjectSelection
        self.onProjectExists = onProjectExists
        self.onRepositoryImported = onRepositoryImported
        self.onActivityStatusUpdate = onActivityStatusUpdate
        self.onInfoMessage = onInfoMessage
        self.onThemeSelection = onThemeSelection
        self.onCleanStatusUpdate = onCleanStatusUpdate
        self.onGitDirectoryChange = onGitDirectoryChange
        self.onUnpushedCommitsUpdate = onUnpushedCommitsUpdate
        self.onRemoteTrackingUpdate = onRemoteTrackingUpdate
    }

    public func resolve<Service>(_ type: Service.Type = Service.self) -> Service? {
        dependencies.resolve(type)
    }
}
