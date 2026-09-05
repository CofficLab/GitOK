import Testing
@testable import KernelCore

@Suite("KernelCore Lifecycle")
@MainActor
struct KernelCoreLifecycleTests {
    private protocol OwnedProviding: AnyObject {}
    private final class OwnedProvider: OwnedProviding {}

    private final class LifecyclePlugin: SuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        var registerProvider = false
        var bootError: Error?
        var readyError: Error?
        var shutdownError: Error?

        init(
            id: String,
            order: Int = 200,
            policy: PluginEnablePolicy = .enabledByDefault,
            events: EventLog
        ) {
            self.id = id
            self.order = order
            self.metadata = PluginMetadata(id: id, policy: policy)
            self.events = events
        }

        func onBoot(kernel: KernelCoreContainer) throws {
            events.values.append("boot:\(id)")
            if registerProvider {
                try kernel.registerProvider(OwnedProviding.self, OwnedProvider())
            }
            if let bootError { throw bootError }
        }

        func onReady(kernel: KernelCoreContainer) throws {
            events.values.append("ready:\(id)")
            if let readyError { throw readyError }
        }

        func onShutdown(kernel: KernelCoreContainer) throws {
            events.values.append("shutdown:\(id)")
            if let shutdownError { throw shutdownError }
        }
    }

    private final class EventLog {
        var values: [String] = []
    }

    private struct TestError: Error {}

    @Test("order 决定启动顺序，全部 Boot 后才进入 Ready")
    func orderDrivesPhases() throws {
        let log = EventLog()
        let early = LifecyclePlugin(id: "early", order: 1, events: log)
        let late = LifecyclePlugin(id: "late", order: 300, events: log)
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [late, early])

        #expect(log.values == ["boot:early", "boot:late", "ready:early", "ready:late"])
        #expect(kernel.lifecycleState == .running)
        #expect(kernel.allPlugins.map(\.id) == ["early", "late"])
    }

    @Test("Ready 失败会逆序 Shutdown 并移除插件拥有的 Provider")
    func readyFailureRollsBack() {
        let log = EventLog()
        let base = LifecyclePlugin(id: "base", events: log)
        base.registerProvider = true
        let feature = LifecyclePlugin(id: "feature", order: 300, events: log)
        feature.readyError = TestError()
        let kernel = KernelCoreContainer()

        #expect(throws: TestError.self) {
            try kernel.start(plugins: [base, feature])
        }

        #expect(log.values.suffix(2) == ["shutdown:feature", "shutdown:base"])
        #expect(kernel.resolveProvider(OwnedProviding.self) == nil)
        #expect(kernel.registeredPluginCount == 0)
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("stop 逆序清理并可再次启动")
    func stopAndRestart() throws {
        let log = EventLog()
        let a = LifecyclePlugin(id: "a", order: 100, events: log)
        let b = LifecyclePlugin(id: "b", order: 200, events: log)
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [b, a])
        try kernel.stop()

        #expect(log.values.suffix(2) == ["shutdown:b", "shutdown:a"])
        #expect(kernel.lifecycleState == .stopped)
        #expect(kernel.registeredPluginCount == 0)

        try kernel.start(plugins: [a])
        #expect(kernel.lifecycleState == .running)
    }
}
