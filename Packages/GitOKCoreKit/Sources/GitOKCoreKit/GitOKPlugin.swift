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

public protocol GitOKPlugin: Sendable {
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

// MARK: - Callback Typealiases

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

public extension GitOKPlugin {
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
