import Combine
import Foundation

/// Dependency bag passed into plugin context (Lumi-style DI).
@MainActor
public final class GitOKPluginDependencies {
    private var services: [ObjectIdentifier: AnyObject] = [:]

    public init() {}

    public func register(_ service: AnyObject, for type: Any.Type) {
        services[ObjectIdentifier(type)] = service
    }

    public func register<Service: AnyObject>(_ service: Service, as type: Service.Type = Service.self) {
        services[ObjectIdentifier(type)] = service
    }

    public func resolve<Service>(_ type: Service.Type = Service.self) -> Service? {
        services[ObjectIdentifier(type)] as? Service
    }
}

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
