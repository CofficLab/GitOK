import Combine
import GitOKUI

/// Theme selection operations exposed to settings and plugins.
@MainActor
public protocol GitOKThemeServicing: AnyObject {
    func selectTheme(_ themeId: String)
    var currentThemeId: String { get }
}

/// Plugin-owned theme contributions consumed by the host theme state.
@MainActor
public protocol GitOKThemeContributionsProviding: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var hasPlugins: Bool { get }
    func themeContributions() -> [GitOKUIThemeContribution]
}
