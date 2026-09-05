import Testing
@testable import KernelCore

/// KernelCore 异步生命周期的运行时操作测试：运行时启用/禁用、异步卸载、
/// 状态守卫与策略约束。模块对应 `KernelCore+AsyncPlugin.swift`。
@Suite("KernelCore Async Runtime")
@MainActor
struct KernelCoreAsyncRuntimeTests {
    private final class EventLog {
        var values: [String] = []
    }

    private struct TestError: Error {}

    /// 可配置策略与事件的异步插件。
    private final class RuntimeAsyncPlugin: AsyncSuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        var onEnableError: Error?

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

        func onBootAsync(kernel: KernelCoreContainer) async throws {
            events.values.append("boot:\(id)")
        }

        func onReadyAsync(kernel: KernelCoreContainer) async throws {
            events.values.append("ready:\(id)")
        }

        func onShutdownAsync(kernel: KernelCoreContainer) async throws {
            events.values.append("shutdown:\(id)")
        }

        func onEnable(kernel: KernelCoreContainer) async throws {
            events.values.append("enable:\(id)")
            if let onEnableError { throw onEnableError }
        }

        func onDisable(kernel: KernelCoreContainer) async throws {
            events.values.append("disable:\(id)")
        }
    }

    /// 同步插件（用于从未 Boot 的同步启用路径）。
    private final class RuntimeSyncPlugin: SuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog

        init(id: String, order: Int = 200, policy: PluginEnablePolicy = .disabledByDefault, events: EventLog) {
            self.id = id
            self.order = order
            self.metadata = PluginMetadata(id: id, policy: policy)
            self.events = events
        }

        func onBoot(kernel: KernelCoreContainer) throws { events.values.append("boot:\(id)") }
        func onReady(kernel: KernelCoreContainer) throws { events.values.append("ready:\(id)") }
        func onShutdown(kernel: KernelCoreContainer) throws { events.values.append("shutdown:\(id)") }
    }

    // MARK: - startAsync 状态守卫

    @Test("startAsync 在 failed 状态抛 invalidLifecycleOperation")
    func startAsyncWhileFailedThrows() async throws {
        let log = EventLog()
        let kernel = KernelCoreContainer()
        let boom = AsyncReadyFailPlugin(id: "boom", events: log)
        await #expect(throws: TestError.self) {
            try await kernel.startAsync(plugins: [boom])
        }
        #expect(kernel.lifecycleState == .failed)

        await #expect(throws: KernelCoreError.self) {
            try await kernel.startAsync(plugins: [RuntimeAsyncPlugin(id: "late", events: log)])
        }
    }

    @Test("startAsync 无可用插件时直接进入 running")
    func startAsyncWithNoActivePlugins() async throws {
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [])
        #expect(kernel.lifecycleState == .running)
    }

    @Test("startAsync 排除 .disabled 策略插件（不注册不启动）")
    func startAsyncExcludesDisabledPolicy() async throws {
        let log = EventLog()
        let disabled = RuntimeAsyncPlugin(id: "disabled", policy: .disabled, events: log)
        let kernel = KernelCoreContainer()

        try await kernel.startAsync(plugins: [disabled])

        #expect(kernel.lifecycleState == .running)
        #expect(!kernel.isPluginRegistered(id: "disabled"))
        #expect(log.values.isEmpty)
    }

    // MARK: - stopAsync 状态守卫

    @Test("stopAsync 在 stopped 状态为静默 no-op")
    func stopAsyncWhenStoppedIsNoop() async throws {
        let kernel = KernelCoreContainer()
        try await kernel.stopAsync()
        #expect(kernel.lifecycleState == .stopped)
    }

    @Test("stopAsync 可清理 failed 状态内核")
    func stopAsyncCleansFailedKernel() async throws {
        let log = EventLog()
        let kernel = KernelCoreContainer()
        // 制造 failed 状态：启动一个会在 ready 抛错的插件。
        let boom = AsyncReadyFailPlugin(id: "boom", events: log)
        await #expect(throws: TestError.self) {
            try await kernel.startAsync(plugins: [boom])
        }
        #expect(kernel.lifecycleState == .failed)

        try await kernel.stopAsync()
        #expect(kernel.lifecycleState == .stopped)
    }

    /// 专门在 ready 阶段抛错的插件。
    private final class AsyncReadyFailPlugin: AsyncSuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        init(id: String, order: Int = 200, events: EventLog) {
            self.id = id
            self.order = order
            self.metadata = PluginMetadata(id: id)
            self.events = events
        }
        func onBootAsync(kernel: KernelCoreContainer) async throws { events.values.append("boot:\(id)") }
        func onReadyAsync(kernel: KernelCoreContainer) async throws { throw TestError() }
        func onShutdownAsync(kernel: KernelCoreContainer) async throws { events.values.append("shutdown:\(id)") }
    }

    // MARK: - disablePlugin 路径

    @Test("disablePlugin 对已禁用插件为 no-op")
    func disableAlreadyDisabledIsNoop() async throws {
        let log = EventLog()
        let plugin = RuntimeAsyncPlugin(id: "off", policy: .disabledByDefault, events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        try await kernel.disablePlugin(id: "off")

        #expect(!kernel.isPluginEnabled(id: "off"))
        // 未走 onDisable（本来就没启用）
        #expect(!log.values.contains("disable:off"))
    }

    @Test("disablePlugin 拒绝 required / alwaysOn 策略")
    func disableRejectsNonConfigurablePolicies() async throws {
        let log = EventLog()
        let kernel = KernelCoreContainer()

        let required = RuntimeAsyncPlugin(id: "req", policy: .required, events: log)
        try await kernel.startAsync(plugins: [required])
        await #expect(throws: KernelCoreError.self) {
            try await kernel.disablePlugin(id: "req")
        }

        let alwaysOn = RuntimeAsyncPlugin(id: "always", policy: .alwaysOn, events: log)
        try await kernel.startAsync(plugins: [alwaysOn])
        await #expect(throws: KernelCoreError.self) {
            try await kernel.disablePlugin(id: "always")
        }
    }

    // MARK: - enablePlugin 路径

    @Test("enablePlugin 对从未 Boot 的同步插件执行完整初始化")
    func enableNeverBootedSyncPlugin() async throws {
        let log = EventLog()
        let plugin = RuntimeSyncPlugin(id: "sync-off", events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: "sync-off"))
        #expect(!kernel.isPluginEnabled(id: "sync-off"))
        #expect(log.values.isEmpty)

        try await kernel.enablePlugin(id: "sync-off")

        #expect(log.values == ["boot:sync-off", "ready:sync-off"])
        #expect(kernel.isPluginEnabled(id: "sync-off"))
    }

    @Test("enablePlugin 对从未 Boot 的异步插件执行完整初始化")
    func enableNeverBootedAsyncPlugin() async throws {
        let log = EventLog()
        let plugin = RuntimeAsyncPlugin(id: "async-off", policy: .disabledByDefault, events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        try await kernel.enablePlugin(id: "async-off")

        #expect(log.values == ["boot:async-off", "ready:async-off"])
        #expect(kernel.isPluginEnabled(id: "async-off"))
    }

    @Test("enablePlugin 的 onEnable 抛错时撤回贡献并传播错误")
    func enablePropagatesOnEnableError() async throws {
        let log = EventLog()
        let plugin = RuntimeAsyncPlugin(id: "flaky", policy: .enabledByDefault, events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])
        try await kernel.disablePlugin(id: "flaky")

        plugin.onEnableError = TestError()
        await #expect(throws: TestError.self) {
            try await kernel.enablePlugin(id: "flaky")
        }
        #expect(!kernel.isPluginEnabled(id: "flaky"))
    }

    // MARK: - unloadPluginAsync 路径

    @Test("unloadPluginAsync 对从未 Boot 的插件跳过 Shutdown 直接注销")
    func unloadAsyncNeverBootedPlugin() async throws {
        let log = EventLog()
        let plugin = RuntimeAsyncPlugin(id: "idle", policy: .disabledByDefault, events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        try await kernel.unloadPluginAsync(id: "idle")

        #expect(!kernel.isPluginRegistered(id: "idle"))
        #expect(!log.values.contains("shutdown:idle"))
    }

    @Test("unloadPluginAsync 的 Shutdown 抛错仍完成注销并传播错误")
    func unloadAsyncPropagatesShutdownError() async throws {
        let log = EventLog()
        let plugin = ShutdownFailingPlugin(id: "shaky", events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        await #expect(throws: TestError.self) {
            try await kernel.unloadPluginAsync(id: "shaky")
        }
        #expect(!kernel.isPluginRegistered(id: "shaky"))
    }

    /// Shutdown 抛错的异步插件。
    private final class ShutdownFailingPlugin: AsyncSuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        init(id: String, order: Int = 200, events: EventLog) {
            self.id = id
            self.order = order
            self.metadata = PluginMetadata(id: id)
            self.events = events
        }
        func onBootAsync(kernel: KernelCoreContainer) async throws {}
        func onReadyAsync(kernel: KernelCoreContainer) async throws {}
        func onShutdownAsync(kernel: KernelCoreContainer) async throws { throw TestError() }
    }

    @Test("stopAsync 的 onUnregister 抛错时仍完成清理并抛出首个错误")
    func stopAsyncCollectsUnregisterError() async throws {
        let log = EventLog()
        let plugin = UnregisterFailingPlugin(id: "leaky", events: log)
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [plugin])

        await #expect(throws: TestError.self) {
            try await kernel.stopAsync()
        }
        #expect(kernel.lifecycleState == .stopped)
        #expect(kernel.registeredPluginCount == 0)
    }

    /// onUnregister 抛错的插件。
    private final class UnregisterFailingPlugin: SuperPlugin {
        let id: String
        let order: Int
        let metadata: PluginMetadata
        let events: EventLog
        init(id: String, order: Int = 200, events: EventLog) {
            self.id = id
            self.order = order
            self.metadata = PluginMetadata(id: id)
            self.events = events
        }
        func onUnregister(kernel: KernelCoreContainer) throws { throw TestError() }
    }
}
