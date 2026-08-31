import Foundation

public enum KernelLifecycleState: String, Sendable {
    case stopped
    case starting
    case running
    case stopping
}

/// Generic plugin lifecycle contract used by the kernel. Domain-specific
/// plugin systems can bridge into it without making KernelCore import them.
@MainActor
public protocol KernelPlugin {
    var id: String { get }
    var order: Int { get }
    var dependencies: [String] { get }

    func onBoot(kernel: KernelCoreContainer) throws
    func onReady(kernel: KernelCoreContainer) throws
    func onShutdown(kernel: KernelCoreContainer) throws
}

public extension KernelPlugin {
    var order: Int { 0 }
    var dependencies: [String] { [] }
    func onReady(kernel: KernelCoreContainer) throws {}
    func onShutdown(kernel: KernelCoreContainer) throws {}
}

/// Lumi-compatible composition kernel.
///
/// KernelCore intentionally knows nothing about GitOK or any concrete feature.
/// Hosts register typed Providers during bootstrap; plugins and views resolve
/// those providers through the same container instance.
@MainActor
public final class KernelCoreContainer {
    private var providers: [ObjectIdentifier: Any] = [:]
    private var plugins: [String: any KernelPlugin] = [:]
    private var pluginStartOrder: [String] = []

    public private(set) var lifecycleState: KernelLifecycleState = .stopped

    public init() {}

    public func registerProvider<T>(_ type: T.Type = T.self, _ provider: T) throws {
        let key = ObjectIdentifier(type)
        guard providers[key] == nil else {
            throw KernelCoreError.providerAlreadyRegistered(
                type: String(reflecting: type)
            )
        }
        providers[key] = provider
    }

    public func resolveProvider<T>(_ type: T.Type = T.self) -> T? {
        providers[ObjectIdentifier(type)] as? T
    }

    public func unregisterProvider<T>(_ type: T.Type = T.self) {
        providers.removeValue(forKey: ObjectIdentifier(type))
    }

    public var registeredProviderCount: Int {
        providers.count
    }

    public var registeredPluginCount: Int {
        plugins.count
    }

    public func resolvePlugin(id: String) -> (any KernelPlugin)? {
        plugins[id]
    }

    public func start() throws {
        try start(plugins: [])
    }

    public func start(plugins incomingPlugins: [any KernelPlugin]) throws {
        guard lifecycleState == .stopped else {
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "start kernel",
                state: lifecycleState
            )
        }
        lifecycleState = .starting

        do {
            let orderedPlugins = try orderedPlugins(from: incomingPlugins)
            for plugin in orderedPlugins {
                plugins[plugin.id] = plugin
                try plugin.onBoot(kernel: self)
                pluginStartOrder.append(plugin.id)
            }
            for id in pluginStartOrder where orderedPlugins.contains(where: { $0.id == id }) {
                try plugins[id]?.onReady(kernel: self)
            }
        } catch {
            for id in pluginStartOrder.reversed() {
                try? plugins[id]?.onShutdown(kernel: self)
            }
            for plugin in incomingPlugins {
                plugins.removeValue(forKey: plugin.id)
            }
            pluginStartOrder.removeAll()
            lifecycleState = .stopped
            throw error
        }
        lifecycleState = .running
    }

    public func stop() throws {
        guard lifecycleState == .running else {
            if lifecycleState == .stopped { return }
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "stop kernel",
                state: lifecycleState
            )
        }
        lifecycleState = .stopping
        for id in pluginStartOrder.reversed() {
            try? plugins[id]?.onShutdown(kernel: self)
            plugins.removeValue(forKey: id)
        }
        pluginStartOrder.removeAll()
        lifecycleState = .stopped
    }

    private func orderedPlugins(from incomingPlugins: [any KernelPlugin]) throws -> [any KernelPlugin] {
        var byID: [String: any KernelPlugin] = [:]
        for plugin in incomingPlugins {
            guard plugins[plugin.id] == nil, byID[plugin.id] == nil else {
                throw KernelCoreError.pluginAlreadyRegistered(id: plugin.id)
            }
            byID[plugin.id] = plugin
        }

        for plugin in incomingPlugins {
            for dependency in plugin.dependencies
                where plugins[dependency] == nil && byID[dependency] == nil {
                throw KernelCoreError.pluginDependencyMissing(
                    pluginID: plugin.id,
                    dependencyID: dependency
                )
            }
        }

        var remaining = Set(byID.keys)
        var resolved = Set(plugins.keys)
        var result: [any KernelPlugin] = []
        while !remaining.isEmpty {
            let ready = remaining.compactMap { byID[$0] }
                .filter { $0.dependencies.allSatisfy { resolved.contains($0) } }
                .sorted { lhs, rhs in
                    lhs.order == rhs.order ? lhs.id < rhs.id : lhs.order < rhs.order
                }
            guard !ready.isEmpty else {
                throw KernelCoreError.pluginDependencyMissing(
                    pluginID: remaining.sorted().joined(separator: ","),
                    dependencyID: "cycle"
                )
            }
            for plugin in ready {
                remaining.remove(plugin.id)
                resolved.insert(plugin.id)
                result.append(plugin)
            }
        }
        return result
    }
}

public typealias KernelCore = KernelCoreContainer
