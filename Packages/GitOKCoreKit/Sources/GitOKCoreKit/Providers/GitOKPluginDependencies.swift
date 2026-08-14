import Combine
import Foundation

/// Type-keyed service registry passed into plugin contexts (Lumi-style DI).
///
/// The kernel holds capabilities, never forwards them: the app shell registers
/// concrete services once at composition time and plugins resolve what they
/// need via ``GitOKPluginContext/resolve(_:)``.
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

    /// Resolves a service erased to `Any.Type`, e.g. for startup validation
    /// over ``GitOKRequiredServices``. Returns `nil` when unregistered.
    public func resolveAny(_ type: Any.Type) -> AnyObject? {
        services[ObjectIdentifier(type)]
    }
}
