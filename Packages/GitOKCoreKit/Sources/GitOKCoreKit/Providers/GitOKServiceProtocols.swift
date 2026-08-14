import Combine
import Foundation
import GitOKUI

// MARK: - Core Services

@MainActor
public protocol GitOKRepositoryServicing: AnyObject {
    func projectExists(at url: URL) -> Bool
    func importRepository(at url: URL) -> Bool
}

@MainActor
public protocol GitOKThemeServicing: AnyObject {
    func selectTheme(_ themeId: String)
    var currentThemeId: String { get }
}

@MainActor
public protocol GitOKActivityServicing: AnyObject {
    var activityStatus: String? { get }
    func setActivityStatus(_ status: String?)
}

@MainActor
public protocol GitOKThemeContributionsProviding: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var hasPlugins: Bool { get }
    func themeContributions() -> [GitOKUIThemeContribution]
}

@MainActor
public protocol GitOKNavigationServicing: AnyObject {
    func openSettings(defaultTab: String?)
    func openSettings(tab: String?)
    func openPluginSettings()
    func openRepositorySettings()
    func openCommitStyleSettings()
}

// MARK: - Required Services

/// Service types the app shell must register before plugins become ready.
///
/// Mirrors the kernel validation contract of a factory host: startup fails
/// loudly, listing exactly what is missing, instead of failing later with
/// cryptic `resolve()` nils scattered across plugin views.
public enum GitOKRequiredServices {
    public static let all: [Any.Type] = [
        GitOKRepositoryServicing.self,
        GitOKActivityServicing.self,
        GitOKGitCommandServicing.self,
        GitOKThemeServicing.self,
        GitOKNavigationServicing.self,
    ]

    @MainActor
    public static func missing(in dependencies: GitOKPluginDependencies) -> [String] {
        all.compactMap { service in
            dependencies.resolveAny(service) == nil ? String(describing: service) : nil
        }
    }
}
