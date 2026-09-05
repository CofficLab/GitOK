import Foundation
import Testing
@testable import KernelCore

/// KernelCore 覆盖率补充：错误描述、启用策略、贡献事务、Provider 归属与同步生命周期边界。
@Suite("KernelCore Misc Coverage")
@MainActor
struct KernelCoreMiscCoverageTests {

    // MARK: - 测试辅助

    private struct TestError: Error {}

    private protocol SampleProviding: AnyObject {}
    private final class SampleProvider: SampleProviding {}

    private protocol UnregisteredProviding: AnyObject {}

    private final class EventLog {
        var values: [String] = []
    }

    /// 可注入事件的同步插件。
    private final class LoggingPlugin: SuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        var registerProvider = false
        var shutdownError: Error?
        var unregisterError: Error?

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
                try kernel.registerProvider(SampleProviding.self, SampleProvider())
            }
            // onBoot 阶段解析未注册 Provider：触发诊断日志路径（不应崩溃）。
            _ = kernel.resolveProvider(UnregisteredProviding.self)
        }

        func onReady(kernel: KernelCoreContainer) throws { events.values.append("ready:\(id)") }

        func onShutdown(kernel: KernelCoreContainer) throws {
            events.values.append("shutdown:\(id)")
            if let shutdownError { throw shutdownError }
        }

        func onUnregister(kernel: KernelCoreContainer) throws {
            events.values.append("unregister:\(id)")
            if let unregisterError { throw unregisterError }
        }
    }

    // MARK: - KernelCoreError 描述

    @Test("全部错误用例的 errorDescription 描述完整")
    func allErrorDescriptions() {
        #expect(
            KernelCoreError.invalidLifecycleOperation(operation: "stop", state: .starting).errorDescription
                == "Cannot stop while kernel is starting"
        )
        #expect(
            KernelCoreError.asyncLifecycleRequired(pluginID: "p").errorDescription
                == "Plugin 'p' requires the asynchronous kernel lifecycle"
        )
        #expect(
            KernelCoreError.pluginRequired(id: "p").errorDescription
                == "Plugin 'p' is required and cannot be disabled"
        )
        #expect(
            KernelCoreError.contributionOwnerUnavailable.errorDescription
                == "A plugin contribution must be registered during a plugin lifecycle callback or with an explicit owner"
        )
        #expect(
            KernelCoreError.lifecycleTimeout(pluginID: "p", phase: "boot").errorDescription
                == "Plugin 'p' exceeded the boot lifecycle timeout"
        )
    }

    // MARK: - PluginEnablePolicy

    @Test("启用策略的可配置性与默认值覆盖全部用例")
    func enablePolicyMatrix() {
        let cases: [(PluginEnablePolicy, Bool, Bool)] = [
            (.required, false, true),
            (.alwaysOn, false, true),
            (.enabledByDefault, true, true),
            (.disabledByDefault, true, false),
            (.disabled, false, false),
        ]
        for (policy, configurable, enabledByDefault) in cases {
            #expect(policy.isConfigurable == configurable, "policy=\(policy)")
            #expect(policy.enabledByDefault == enabledByDefault, "policy=\(policy)")
        }
    }

    // MARK: - AsyncSuperPlugin 默认转发

    @Test("AsyncSuperPlugin 默认实现转发到同步方法")
    func asyncDefaultsForwardToSync() async throws {
        let events = EventLog()
        final class ForwardingPlugin: AsyncSuperPlugin {
            let id = "forward"
            let metadata = PluginMetadata(id: "forward")
            let events: EventLog
            init(events: EventLog) { self.events = events }
            func onBoot(kernel: KernelCoreContainer) throws { events.values.append("boot") }
            func onReady(kernel: KernelCoreContainer) throws { events.values.append("ready") }
            func onShutdown(kernel: KernelCoreContainer) throws { events.values.append("shutdown") }
        }
        let plugin = ForwardingPlugin(events: events)
        let kernel = KernelCoreContainer()
        let asyncPlugin: any AsyncSuperPlugin = plugin

        try await asyncPlugin.onBootAsync(kernel: kernel)
        try await asyncPlugin.onReadyAsync(kernel: kernel)
        try await asyncPlugin.onShutdownAsync(kernel: kernel)

        #expect(events.values == ["boot", "ready", "shutdown"])
    }

    // MARK: - 贡献事务

    @Test("事务 commit 后由 Kernel 接管清理")
    func transactionCommitTransfersOwnership() throws {
        let kernel = KernelCoreContainer()
        let plugin = LoggingPlugin(id: "owner", events: EventLog())
        try kernel.registerPlugin(plugin)

        var cleaned: [String] = []
        let transaction = PluginContributionTransaction()
        transaction.addCleanup { cleaned.append("first") }
        transaction.addCleanup { cleaned.append("second") }

        let tokens = try transaction.commit(to: kernel, ownerPluginID: plugin.id)
        #expect(tokens.count == 2)
        #expect(kernel.activeContributionCount(ownedBy: plugin.id) == 2)
        #expect(cleaned.isEmpty)

        // commit 后事务不再接收新 cleanup，再次 commit 返回空。
        transaction.addCleanup { cleaned.append("late") }
        #expect(try transaction.commit(to: kernel, ownerPluginID: plugin.id).isEmpty)

        kernel.cancelContributions(ownedBy: plugin.id)
        #expect(cleaned == ["second", "first"])
        #expect(kernel.activeContributionCount(ownedBy: plugin.id) == 0)
    }

    @Test("贡献 token 取消幂等")
    func contributionTokenCancelIsIdempotent() throws {
        let kernel = KernelCoreContainer()
        let plugin = LoggingPlugin(id: "explicit", events: EventLog())
        try kernel.registerPlugin(plugin)
        var count = 0
        let token = try kernel.trackContribution(ownerPluginID: "explicit") { count += 1 }

        token.cancel()
        token.cancel()

        #expect(count == 1)
        #expect(!token.isActive)
    }

    @Test("trackContribution 显式指定已注册 owner 在生命周期外可用")
    func trackContributionWithExplicitOwner() throws {
        let kernel = KernelCoreContainer()
        let plugin = LoggingPlugin(id: "p", events: EventLog())
        try kernel.registerPlugin(plugin)

        #expect(try kernel.trackContribution(ownerPluginID: "p") {} .isActive)
    }

    @Test("trackContribution 指定未注册 owner 抛错")
    func trackContributionUnknownOwnerThrows() {
        let kernel = KernelCoreContainer()
        #expect(throws: KernelCoreError.self) {
            try kernel.trackContribution(ownerPluginID: "ghost") {}
        }
    }

    // MARK: - Provider 归属

    @Test("onBoot 注册的 Provider 归属插件，注销插件时被移除")
    func providerOwnershipAndRemoval() throws {
        let events = EventLog()
        let plugin = LoggingPlugin(id: "host", events: events)
        plugin.registerProvider = true
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [plugin])

        #expect(kernel.isProvider(SampleProviding.self, ownedByPlugin: "host"))
        #expect(kernel.resolveProvider(SampleProviding.self) != nil)

        try kernel.stop()

        #expect(kernel.resolveProvider(SampleProviding.self) == nil)
        #expect(!kernel.isProvider(SampleProviding.self, ownedByPlugin: "host"))
    }

    // MARK: - 同步生命周期边界

    @Test("stop 在 stopped 状态为静默 no-op")
    func stopWhenStoppedIsNoop() throws {
        let kernel = KernelCoreContainer()
        try kernel.stop()
        #expect(kernel.lifecycleState == .stopped)
    }

    @Test("failed 状态下再次 start 抛 invalidLifecycleOperation")
    func startAfterFailureThrows() {
        let events = EventLog()
        struct BootError: Error {}
        final class BadPlugin: SuperPlugin {
            let id = "bad"
            let metadata = PluginMetadata(id: "bad")
            let events: EventLog
            init(events: EventLog) { self.events = events }
            func onBoot(kernel: KernelCoreContainer) throws {
                events.values.append("boot")
                throw BootError()
            }
        }
        let kernel = KernelCoreContainer()
        #expect(throws: BootError.self) {
            try kernel.start(plugins: [BadPlugin(events: events)])
        }
        #expect(kernel.lifecycleState == .failed)

        #expect(throws: KernelCoreError.self) {
            try kernel.start(plugins: [LoggingPlugin(id: "new", events: events)])
        }
    }

    @Test("stop 的 Shutdown 抛错仍清理其余插件并抛出首个错误")
    func stopCollectsShutdownError() throws {
        let events = EventLog()
        let bad = LoggingPlugin(id: "bad", order: 100, events: events)
        bad.shutdownError = TestError()
        let good = LoggingPlugin(id: "good", order: 200, events: events)
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [bad, good])
        #expect(throws: TestError.self) {
            try kernel.stop()
        }
        // 逆序 Shutdown，随后逆序 Unregister；错误来自 bad 的 Shutdown。
        #expect(events.values.suffix(4) == ["shutdown:good", "shutdown:bad", "unregister:good", "unregister:bad"])
        #expect(kernel.registeredPluginCount == 0)
        #expect(kernel.lifecycleState == .stopped)
    }

    @Test("stop 的 onUnregister 抛错仍完成清理并抛出首个错误")
    func stopCollectsUnregisterError() throws {
        let events = EventLog()
        let plugin = LoggingPlugin(id: "leaky", events: events)
        plugin.unregisterError = TestError()
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [plugin])
        #expect(throws: TestError.self) {
            try kernel.stop()
        }
        #expect(kernel.registeredPluginCount == 0)
        #expect(kernel.lifecycleState == .stopped)
    }

    @Test("stop 拒绝含异步插件的内核")
    func stopRejectsAsyncPlugin() throws {
        let events = EventLog()
        let kernel = KernelCoreContainer()
        let sync = LoggingPlugin(id: "sync", events: events)
        try kernel.start(plugins: [sync])

        final class QuietAsync: AsyncSuperPlugin {
            let id = "async"
            let metadata = PluginMetadata(id: "async")
        }
        try kernel.registerPlugin(QuietAsync())

        #expect(throws: KernelCoreError.self) {
            try kernel.stop()
        }
    }

    @Test("unloadPlugin 对从未 Boot 的插件跳过 Shutdown")
    func unloadNeverBootedSkipsShutdown() throws {
        let events = EventLog()
        let idle = LoggingPlugin(id: "idle", policy: .disabledByDefault, events: events)
        let kernel = KernelCoreContainer()

        try kernel.start(plugins: [idle])
        #expect(!kernel.isPluginEnabled(id: "idle"))
        #expect(events.values.isEmpty)

        try kernel.unloadPlugin(id: "idle")

        #expect(!kernel.isPluginRegistered(id: "idle"))
        #expect(!events.values.contains("shutdown:idle"))
        #expect(events.values.contains("unregister:idle"))
    }

    @Test("unloadPlugin 的 Shutdown 抛错仍完成注销并传播")
    func unloadPropagatesShutdownError() throws {
        let events = EventLog()
        let plugin = LoggingPlugin(id: "shaky", events: events)
        plugin.shutdownError = TestError()
        let kernel = KernelCoreContainer()
        try kernel.start(plugins: [plugin])

        #expect(throws: TestError.self) {
            try kernel.unloadPlugin(id: "shaky")
        }
        #expect(!kernel.isPluginRegistered(id: "shaky"))
    }

    @Test("unregisterPlugin 容忍 onUnregister 抛错")
    func unregisterSwallowsUnregisterError() throws {
        let events = EventLog()
        let plugin = LoggingPlugin(id: "loud", events: events)
        plugin.unregisterError = TestError()
        let kernel = KernelCoreContainer()
        try kernel.registerPlugin(plugin)

        kernel.unregisterPlugin(id: "loud")

        #expect(!kernel.isPluginRegistered(id: "loud"))
    }

    // MARK: - 启用状态持久化

    private final class MockStateStore: PluginStatePersisting {
        var states: [String: Bool] = [:]
        func enabledState(pluginID: String) -> Bool? { states[pluginID] }
        func setEnabled(_ enabled: Bool, pluginID: String) { states[pluginID] = enabled }
        func removeState(pluginID: String) { states.removeValue(forKey: pluginID) }
    }

    @Test("持久化覆盖优先于 disabledByDefault 策略默认值")
    func persistedStateOverridesDisabledDefault() throws {
        let store = MockStateStore()
        store.states["remembered"] = true
        let kernel = KernelCoreContainer()
        kernel.stateStore = store
        let plugin = LoggingPlugin(id: "remembered", policy: .disabledByDefault, events: EventLog())

        try kernel.registerPlugin(plugin)

        #expect(kernel.isPluginEnabled(id: "remembered"))
    }

    @Test("persistEnabledState 同时写入新旧 id 别名")
    func persistWritesLegacyAlias() throws {
        let store = MockStateStore()
        let kernel = KernelCoreContainer()
        kernel.stateStore = store
        kernel.legacyPluginIDAliases["new-id"] = "old-id"
        let plugin = LoggingPlugin(id: "new-id", events: EventLog())
        try kernel.registerPlugin(plugin)

        kernel.persistEnabledState(false, pluginID: "new-id")

        #expect(store.states["new-id"] == false)
        #expect(store.states["old-id"] == false)
    }

    @Test("旧 id 别名在读取时回退")
    func storedStateFallsBackToLegacyAlias() throws {
        let store = MockStateStore()
        store.states["old-id"] = false
        let kernel = KernelCoreContainer()
        kernel.stateStore = store
        kernel.legacyPluginIDAliases["new-id"] = "old-id"
        let plugin = LoggingPlugin(id: "new-id", policy: .enabledByDefault, events: EventLog())

        try kernel.registerPlugin(plugin)

        // 新 id 无记录，回退旧 id 的 false → 不启用。
        #expect(!kernel.isPluginEnabled(id: "new-id"))
    }
}
