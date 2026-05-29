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

    func toolBarTrailingView() -> AnyView?

    @MainActor
    func rootView(_ content: AnyView) -> AnyView?

    @MainActor
    func statusBarLeadingView() -> AnyView?

    @MainActor
    func statusBarCenterView() -> AnyView?

    @MainActor
    func statusBarTrailingView() -> AnyView?

    @MainActor
    func themeContributions() -> [GitOKUIThemeContribution]
}

private struct GitOKProjectURLEnvironmentKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

private struct GitOKActivityStatusEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

private struct GitOKSelectedFilePathEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

private struct GitOKProjectPathEnvironmentKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

public typealias GitOKThemeSelectionHandler = @MainActor (String) -> Void
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

private struct GitOKThemeSelectionHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKThemeSelectionHandler = { themeId in
        try? GitOKUIThemeRegistry.shared.select(themeId: themeId)
    }
}

private struct GitOKCleanStatusUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKCleanStatusUpdateHandler = { _ in }
}

private struct GitOKGitDirectoryChangeHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKGitDirectoryChangeHandler = { _ in }
}

private struct GitOKUnpushedCommitsUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKUnpushedCommitsUpdateHandler = { _, _ in }
}

private struct GitOKRemoteTrackingUpdateHandlerEnvironmentKey: EnvironmentKey {
    static let defaultValue: GitOKRemoteTrackingUpdateHandler = { _, _ in }
}

public extension EnvironmentValues {
    var gitOKProjectURL: URL? {
        get { self[GitOKProjectURLEnvironmentKey.self] }
        set { self[GitOKProjectURLEnvironmentKey.self] = newValue }
    }

    var gitOKActivityStatus: String? {
        get { self[GitOKActivityStatusEnvironmentKey.self] }
        set { self[GitOKActivityStatusEnvironmentKey.self] = newValue }
    }

    var gitOKSelectedFilePath: String? {
        get { self[GitOKSelectedFilePathEnvironmentKey.self] }
        set { self[GitOKSelectedFilePathEnvironmentKey.self] = newValue }
    }

    var gitOKProjectPath: String? {
        get { self[GitOKProjectPathEnvironmentKey.self] }
        set { self[GitOKProjectPathEnvironmentKey.self] = newValue }
    }

    var gitOKThemeSelectionHandler: GitOKThemeSelectionHandler {
        get { self[GitOKThemeSelectionHandlerEnvironmentKey.self] }
        set { self[GitOKThemeSelectionHandlerEnvironmentKey.self] = newValue }
    }

    var gitOKCleanStatusUpdateHandler: GitOKCleanStatusUpdateHandler {
        get { self[GitOKCleanStatusUpdateHandlerEnvironmentKey.self] }
        set { self[GitOKCleanStatusUpdateHandlerEnvironmentKey.self] = newValue }
    }

    var gitOKGitDirectoryChangeHandler: GitOKGitDirectoryChangeHandler {
        get { self[GitOKGitDirectoryChangeHandlerEnvironmentKey.self] }
        set { self[GitOKGitDirectoryChangeHandlerEnvironmentKey.self] = newValue }
    }

    var gitOKUnpushedCommitsUpdateHandler: GitOKUnpushedCommitsUpdateHandler {
        get { self[GitOKUnpushedCommitsUpdateHandlerEnvironmentKey.self] }
        set { self[GitOKUnpushedCommitsUpdateHandlerEnvironmentKey.self] = newValue }
    }

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

    func toolBarTrailingView() -> AnyView? {
        nil
    }

    @MainActor
    func rootView(_ content: AnyView) -> AnyView? {
        nil
    }

    @MainActor
    func statusBarLeadingView() -> AnyView? {
        nil
    }

    @MainActor
    func statusBarCenterView() -> AnyView? {
        nil
    }

    @MainActor
    func statusBarTrailingView() -> AnyView? {
        nil
    }

    @MainActor
    func themeContributions() -> [GitOKUIThemeContribution] {
        []
    }
}
