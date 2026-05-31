import Foundation

/// 插件视图构建上下文
///
/// 在插件构建视图时提供的上下文，承载内核运行时的状态信息。
/// GitOKPluginKit 中定义最小化版本，内核在运行时注入实际数据。
///
/// ## 扩展指南
///
/// 当需要向插件传递更多上下文信息时，在此结构体中添加新属性即可。
/// 所有新增属性应提供合理的默认值，以保持向后兼容性。
@MainActor
public struct GitOKPluginContext {
    /// 当前长运行任务的描述文本
    ///
    /// 当应用正在执行 git 操作（如 clone、push、pull 等）时，
    /// 内核会设置此值以展示进度状态。
    /// 为 `nil` 表示当前无活动任务。
    public let activityStatus: String?

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

    public init(
        activityStatus: String? = nil,
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false,
        selectedFilePath: String? = nil
    ) {
        self.activityStatus = activityStatus
        self.projectURL = projectURL
        self.projectPath = projectPath
        self.projectTitle = projectTitle
        self.branchName = branchName
        self.isGitRepository = isGitRepository
        self.selectedFilePath = selectedFilePath
    }
}
