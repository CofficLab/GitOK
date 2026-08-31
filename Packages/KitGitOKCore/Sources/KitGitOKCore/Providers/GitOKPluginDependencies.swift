import Combine
import Foundation
import KernelCore

/// Type-keyed service registry passed into plugin contexts (Lumi-style DI).
///
/// The kernel holds capabilities, never forwards them: the app shell registers
/// concrete services once at composition time and plugins resolve what they
/// need via ``GitOKPluginContext/resolve(_:)``.
@MainActor
public final class GitOKPluginDependencies {
    private var services: [ObjectIdentifier: AnyObject] = [:]
    private weak var kernel: KernelCoreContainer?

    public init(kernel: KernelCoreContainer? = nil) {
        self.kernel = kernel
    }

    public func register(_ service: AnyObject, for type: Any.Type) {
        services[ObjectIdentifier(type)] = service
        if let kernel {
            try? kernel.registerProvider(service, for: type)
        }
    }

    public func register<Service: AnyObject>(_ service: Service, as type: Service.Type = Service.self) {
        services[ObjectIdentifier(type)] = service
        if let kernel {
            try? kernel.registerProvider(type, service)
        }
    }

    public func resolve<Service>(_ type: Service.Type = Service.self) -> Service? {
        kernel?.resolveProvider(type) ?? services[ObjectIdentifier(type)] as? Service
    }

    /// Resolves a service erased to `Any.Type`, e.g. for startup validation
    /// over ``GitOKRequiredServices``. Returns `nil` when unregistered.
    public func resolveAny(_ type: Any.Type) -> AnyObject? {
        if let kernelValue = kernel?.resolveProviderErased(type) {
            return kernelValue as AnyObject
        }
        return services[ObjectIdentifier(type)]
    }
}
