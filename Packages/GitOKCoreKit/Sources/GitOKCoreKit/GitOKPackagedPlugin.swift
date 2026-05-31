import GitOKUI
import SwiftUI

public struct GitOKPluginMetadata: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String
    public let iconName: String
    public let order: Int
    public let allowUserToggle: Bool
    public let defaultEnabled: Bool
    public let tableName: String

    public init(
        id: String,
        displayName: String,
        description: String,
        iconName: String = "puzzlepiece.extension",
        order: Int = 9999,
        allowUserToggle: Bool = true,
        defaultEnabled: Bool = true,
        tableName: String
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.iconName = iconName
        self.order = order
        self.allowUserToggle = allowUserToggle
        self.defaultEnabled = defaultEnabled
        self.tableName = tableName
    }
}

public protocol GitOKPackagedPlugin: Sendable {
    static var metadata: GitOKPluginMetadata { get }
    static var shouldRegister: Bool { get }
    static var shared: Self { get }

    var instanceLabel: String { get }

    func tabItem() -> String?

    @MainActor
    func toolBarLeadingView(context: GitOKPluginContext) -> AnyView?

    @MainActor
    func toolBarTrailingView(context: GitOKPluginContext) -> AnyView?

    @MainActor
    func rootView(_ content: AnyView, context: GitOKPluginContext) -> AnyView?

    @MainActor
    func statusBarLeadingView(context: GitOKPluginContext) -> AnyView?

    @MainActor
    func statusBarCenterView(context: GitOKPluginContext) -> AnyView?

    @MainActor
    func statusBarTrailingView(context: GitOKPluginContext) -> AnyView?

    @MainActor
    func themeContributions() -> [GitOKUIThemeContribution]
}

// MARK: - Deprecated Environment Keys

// 这些 Environment Key 已废弃，插件应改用 GitOKPluginContext 获取运行时状态。
// 保留仅为向后兼容。

@available(*, deprecated, message: "Use GitOKPluginContext.projectURL instead")
private struct GitOKProjectURLEnvironmentKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.activityStatus instead")
private struct GitOKActivityStatusEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.selectedFilePath instead")
private struct GitOKSelectedFilePathEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.projectPath instead")
private struct GitOKProjectPathEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.projectTitle instead")
private struct GitOKProjectTitleEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.branchName instead")
private struct GitOKBranchNameEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.isGitRepository instead")
private struct GitOKIsGitRepositoryEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(*, deprecated, message: "Use GitOKPluginContext.remoteTrackingStatus instead")
private struct GitOKRemoteTrackingStatusEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKRemoteTrackingStatus? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.projects instead")
private struct GitOKProjectsEnvironmentKey: EnvironmentKey {
    static let defaultValue: [GitOKProjectSummary] = []
}

@available(*, deprecated, message: "Use GitOKPluginContext.selectedProjectURL instead")
private struct GitOKSelectedProjectURLEnvironmentKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

@available(*, deprecated, message: "Use GitOKPluginContext.isSidebarVisible instead")
private struct GitOKSidebarVisibleEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

public typealias GitOKThemeSelectionHandler = @MainActor (String) -> Void
public typealias GitOKProjectSelectionHandler = @MainActor (URL) -> Void
public typealias GitOKCleanStatusUpdateHandler = @MainActor (Bool) -> Void
public typealias GitOKGitDirectoryChangeHandler = @MainActor (GitOKGitDirectoryChange) -> Void
public typealias GitOKUnpushedCommitsUpdateHandler = @MainActor (Int, [String]) -> Void
public typealias GitOKRemoteTrackingUpdateHandler = @MainActor (GitOKRemoteTrackingStatus?, Date?) -> Void

public struct GitOKGitDirectoryChange: Equatable, Sendable {
    public let projectURL: URL
    public let gitDirectoryPath: String
    public let changeKind: String
    public let headChanged: Bool
    public let indexChanged: Bool
    public let stashChanged: Bool
    public let refsChanged: Bool
    public let previousHead: String?
    public let head: String?

    public init(
        projectURL: URL,
        gitDirectoryPath: String,
        changeKind: String,
        headChanged: Bool,
        indexChanged: Bool,
        stashChanged: Bool,
        refsChanged: Bool,
        previousHead: String? = nil,
        head: String? = nil
    ) {
        self.projectURL = projectURL
        self.gitDirectoryPath = gitDirectoryPath
        self.changeKind = changeKind
        self.headChanged = headChanged
        self.indexChanged = indexChanged
        self.stashChanged = stashChanged
        self.refsChanged = refsChanged
        self.previousHead = previousHead
        self.head = head
    }
}

public struct GitOKProjectSummary: Identifiable, Equatable, Sendable, Hashable {
    public let url: URL
    public let title: String
    public let path: String

    public init(url: URL, title: String, path: String) {
        self.url = url
        self.title = title
        self.path = path
    }

    public var id: URL { url }
}

public struct GitOKRemoteTrackingStatus: Equatable, Sendable {
    public let ahead: Int
    public let behind: Int
    public let hasUpstream: Bool

    public init(ahead: Int, behind: Int, hasUpstream: Bool) {
        self.ahead = ahead
        self.behind = behind
        self.hasUpstream = hasUpstream
    }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onThemeSelection instead")
private struct GitOKThemeSelectionHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKThemeSelectionHandler = { themeId in
        try? GitOKUIThemeRegistry.shared.select(themeId: themeId)
    }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onProjectSelection instead")
private struct GitOKProjectSelectionHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKProjectSelectionHandler = { _ in }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onCleanStatusUpdate instead")
private struct GitOKCleanStatusUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKCleanStatusUpdateHandler = { _ in }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onGitDirectoryChange instead")
private struct GitOKGitDirectoryChangeHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKGitDirectoryChangeHandler = { _ in }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onUnpushedCommitsUpdate instead")
private struct GitOKUnpushedCommitsUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKUnpushedCommitsUpdateHandler = { _, _ in }
}

@available(*, deprecated, message: "Use GitOKPluginContext.onRemoteTrackingUpdate instead")
private struct GitOKRemoteTrackingUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKRemoteTrackingUpdateHandler = { _, _ in }
}

// MARK: - Deprecated EnvironmentValues Extensions

// 这些 EnvironmentValues 扩展已废弃，插件应改用 GitOKPluginContext 获取运行时状态。
// 保留仅为向后兼容。

public extension EnvironmentValues {
    @available(*, deprecated, message: "Use GitOKPluginContext.projectURL instead")
    var gitOKProjectURL: URL? {
        get { self[GitOKProjectURLEnvironmentKey.self] }
        set { self[GitOKProjectURLEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.activityStatus instead")
    var gitOKActivityStatus: String? {
        get { self[GitOKActivityStatusEnvironmentKey.self] }
        set { self[GitOKActivityStatusEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.selectedFilePath instead")
    var gitOKSelectedFilePath: String? {
        get { self[GitOKSelectedFilePathEnvironmentKey.self] }
        set { self[GitOKSelectedFilePathEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.projectPath instead")
    var gitOKProjectPath: String? {
        get { self[GitOKProjectPathEnvironmentKey.self] }
        set { self[GitOKProjectPathEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.projectTitle instead")
    var gitOKProjectTitle: String? {
        get { self[GitOKProjectTitleEnvironmentKey.self] }
        set { self[GitOKProjectTitleEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.branchName instead")
    var gitOKBranchName: String? {
        get { self[GitOKBranchNameEnvironmentKey.self] }
        set { self[GitOKBranchNameEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.isGitRepository instead")
    var gitOKIsGitRepository: Bool {
        get { self[GitOKIsGitRepositoryEnvironmentKey.self] }
        set { self[GitOKIsGitRepositoryEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.remoteTrackingStatus instead")
    var gitOKRemoteTrackingStatus: GitOKRemoteTrackingStatus? {
        get { self[GitOKRemoteTrackingStatusEnvironmentKey.self] }
        set { self[GitOKRemoteTrackingStatusEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.projects instead")
    var gitOKProjects: [GitOKProjectSummary] {
        get { self[GitOKProjectsEnvironmentKey.self] }
        set { self[GitOKProjectsEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.selectedProjectURL instead")
    var gitOKSelectedProjectURL: URL? {
        get { self[GitOKSelectedProjectURLEnvironmentKey.self] }
        set { self[GitOKSelectedProjectURLEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.isSidebarVisible instead")
    var gitOKSidebarVisible: Bool {
        get { self[GitOKSidebarVisibleEnvironmentKey.self] }
        set { self[GitOKSidebarVisibleEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onProjectSelection instead")
    var gitOKProjectSelectionHandler: GitOKProjectSelectionHandler {
        get { self[GitOKProjectSelectionHandlerEnvironmentKey.self] }
        set { self[GitOKProjectSelectionHandlerEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onThemeSelection instead")
    var gitOKThemeSelectionHandler: GitOKThemeSelectionHandler {
        get { self[GitOKThemeSelectionHandlerEnvironmentKey.self] }
        set { self[GitOKThemeSelectionHandlerEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onCleanStatusUpdate instead")
    var gitOKCleanStatusUpdateHandler: GitOKCleanStatusUpdateHandler {
        get { self[GitOKCleanStatusUpdateHandlerEnvironmentKey.self] }
        set { self[GitOKCleanStatusUpdateHandlerEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onGitDirectoryChange instead")
    var gitOKGitDirectoryChangeHandler: GitOKGitDirectoryChangeHandler {
        get { self[GitOKGitDirectoryChangeHandlerEnvironmentKey.self] }
        set { self[GitOKGitDirectoryChangeHandlerEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onUnpushedCommitsUpdate instead")
    var gitOKUnpushedCommitsUpdateHandler: GitOKUnpushedCommitsUpdateHandler {
        get { self[GitOKUnpushedCommitsUpdateHandlerEnvironmentKey.self] }
        set { self[GitOKUnpushedCommitsUpdateHandlerEnvironmentKey.self] = newValue }
    }

    @available(*, deprecated, message: "Use GitOKPluginContext.onRemoteTrackingUpdate instead")
    var gitOKRemoteTrackingUpdateHandler: GitOKRemoteTrackingUpdateHandler {
        get { self[GitOKRemoteTrackingUpdateHandlerEnvironmentKey.self] }
        set { self[GitOKRemoteTrackingUpdateHandlerEnvironmentKey.self] = newValue }
    }
}

public extension GitOKPackagedPlugin {
    static var shouldRegister: Bool { true }

    var instanceLabel: String {
        Self.metadata.id
    }

    func tabItem() -> String? {
        nil
    }

    @MainActor
    func toolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func rootView(_ content: AnyView, context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func statusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func statusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    @MainActor
    func themeContributions() -> [GitOKUIThemeContribution] {
        []
    }
}
