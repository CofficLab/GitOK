import Foundation
import GitOKUI
import SwiftUI

public enum GitOKPluginPolicy: String, Sendable, Codable {
  case alwaysOn
  case optOut
  case optIn
  case disabled

  public var shouldRegister: Bool {
    switch self {
    case .alwaysOn, .optOut, .optIn:
      true
    case .disabled:
      false
    }
  }

  public var allowUserToggle: Bool {
    switch self {
    case .optOut, .optIn:
      true
    case .alwaysOn, .disabled:
      false
    }
  }

  public var defaultEnabled: Bool {
    switch self {
    case .alwaysOn, .optOut:
      true
    case .optIn, .disabled:
      false
    }
  }
}

public struct GitOKPluginMetadata: Equatable, Sendable {
  public let id: String
  public let displayName: String
  public let description: String
  public let iconName: String
  public let order: Int
  public let policy: GitOKPluginPolicy
  public let tableName: String

  public var allowUserToggle: Bool { policy.allowUserToggle }
  public var defaultEnabled: Bool { policy.defaultEnabled }

  public init(
    id: String,
    displayName: String,
    description: String,
    iconName: String = "puzzlepiece.extension",
    order: Int = 9999,
    policy: GitOKPluginPolicy = .disabled,
    tableName: String
  ) {
    self.id = id
    self.displayName = displayName
    self.description = description
    self.iconName = iconName
    self.order = order
    self.policy = policy
    self.tableName = tableName
  }
}

public protocol GitOKPlugin {
    static var metadata: GitOKPluginMetadata { get }
    static var policy: GitOKPluginPolicy { get }
    static var shouldRegister: Bool { get }

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem]

    @MainActor
    static func toolbarLeadingItems(context: GitOKPluginContext) -> [GitOKToolbarItem]

    @MainActor
    static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem]

    @MainActor
    static func listPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKListPaneItem]

    @MainActor
    static func railPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKRailItem]

    @MainActor
    static func detailPaneItems(context: GitOKPluginContext, tab: String) -> [DetailPane]

    @MainActor
    static func statusBarLeadingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem]

    @MainActor
    static func statusBarCenterItems(context: GitOKPluginContext) -> [GitOKStatusBarItem]

    @MainActor
    static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem]

    @MainActor
    static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution]

    @MainActor
    static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView?

    @MainActor
    static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem]

    @MainActor
    static func sidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution]

    @MainActor
    static func onboardingPaneItems(context: GitOKPluginContext) -> [GitOKOnboardingPaneItem]

    /// 插件管理页中的介绍视图（可选）。
    @MainActor
    static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView?
}

// MARK: - Callback Typealiases

public typealias GitOKThemeSelectionHandler = @MainActor (String) -> Void
public typealias GitOKProjectSelectionHandler = @MainActor (URL) -> Void
public typealias GitOKProjectExistenceHandler = @MainActor (URL) -> Bool
public typealias GitOKRepositoryImportCompletionHandler = @MainActor (URL) -> Bool
public typealias GitOKActivityStatusUpdateHandler = @MainActor (String?) -> Void
public typealias GitOKUserMessageHandler = @MainActor (String) -> Void
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
    static var policy: GitOKPluginPolicy { metadata.policy }
    static var shouldRegister: Bool { policy.shouldRegister }

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] { [] }

    @MainActor
    static func toolbarLeadingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] { [] }

    @MainActor
    static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] { [] }

    @MainActor
    static func listPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKListPaneItem] { [] }

    @MainActor
    static func railPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKRailItem] { [] }

    @MainActor
    static func detailPaneItems(context: GitOKPluginContext, tab: String) -> [DetailPane] { [] }

    @MainActor
    static func statusBarLeadingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] { [] }

    @MainActor
    static func statusBarCenterItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] { [] }

    @MainActor
    static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] { [] }

    @MainActor
    static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] { [] }

    @MainActor
    static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? { nil }

    @MainActor
    static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] { [] }

    @MainActor
    static func sidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution] { [] }

    @MainActor
    static func onboardingPaneItems(context: GitOKPluginContext) -> [GitOKOnboardingPaneItem] { [] }

    /// Template kind for the default plugin introduction view in settings.
    static var introductionContentKind: GitOKPluginAboutContentKind { .general }

    /// 插件管理页中的介绍视图。默认使用模板化自我介绍页。
    @MainActor
    static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        pluginAboutView(kind: introductionContentKind)
    }

    @MainActor
    static func pluginAboutView(
        kind: GitOKPluginAboutContentKind,
        footnote: String? = nil
    ) -> AnyView {
        AnyView(
            GitOKPluginAboutView(
                icon: metadata.iconName,
                displayName: metadata.displayName,
                description: metadata.description,
                kind: kind,
                footnote: footnote
            )
        )
    }

    @MainActor
    static func openInUnavailableFootnote() -> String {
        GitOKPluginAboutLocalization.format("about.openIn.footnote.notInstalled", metadata.displayName)
    }

    @MainActor
    static func pluginIntroductionCard(footnote: String? = nil) -> AnyView {
        pluginAboutView(kind: introductionContentKind, footnote: footnote)
    }
}
