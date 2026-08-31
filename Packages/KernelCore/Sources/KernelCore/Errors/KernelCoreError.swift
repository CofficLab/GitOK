import Foundation

public enum KernelCoreError: LocalizedError, Equatable {
    case providerAlreadyRegistered(type: String)
    case pluginAlreadyRegistered(id: String)
    case pluginDependencyMissing(pluginID: String, dependencyID: String)
    case invalidLifecycleOperation(operation: String, state: KernelLifecycleState)

    public var errorDescription: String? {
        switch self {
        case let .providerAlreadyRegistered(type):
            return "Provider already registered: \(type)"
        case let .pluginAlreadyRegistered(id):
            return "Plugin already registered: \(id)"
        case let .pluginDependencyMissing(pluginID, dependencyID):
            return "Plugin \(pluginID) requires missing plugin \(dependencyID)"
        case let .invalidLifecycleOperation(operation, state):
            return "Cannot \(operation) while kernel is \(state.rawValue)"
        }
    }
}
