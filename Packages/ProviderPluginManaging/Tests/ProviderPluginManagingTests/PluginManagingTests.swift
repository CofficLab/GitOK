import Foundation
import KernelCore
import ProviderPluginControl
import XCTest
@testable import ProviderPluginManaging

@MainActor
final class PluginManagingTests: XCTestCase {
    @MainActor
    private final class FakePlugin: SuperPlugin {
        let id: String
        let order: Int
        let category: PluginCategory
        let policy: PluginEnablePolicy

        init(
            id: String,
            order: Int = 10,
            category: PluginCategory = .general,
            policy: PluginEnablePolicy = .enabledByDefault
        ) {
            self.id = id
            self.order = order
            self.category = category
            self.policy = policy
        }

        var metadata: PluginMetadata {
            PluginMetadata(
                id: id,
                name: id,
                description: "Fake",
                category: category,
                stage: .stable,
                policy: policy
            )
        }
    }

    func testAllPluginsAndConfigurableFilter() throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let toggleable = FakePlugin(id: "toggleable", policy: .enabledByDefault)
        let required = FakePlugin(id: "required", policy: .required)
        try kernel.registerPlugin(toggleable)
        try kernel.registerPlugin(required)

        XCTAssertEqual(manager.pluginCount, 2)
        XCTAssertEqual(manager.configurablePlugins.map(\.id), ["toggleable"])
    }

    func testEnabledCountReflectsKernel() throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let a = FakePlugin(id: "a")
        try kernel.registerPlugin(a)
        XCTAssertEqual(manager.enabledCount, 1)
        XCTAssertTrue(manager.isEnabled(id: "a"))
    }

    func testPluginLookup() throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let a = FakePlugin(id: "a")
        try kernel.registerPlugin(a)
        XCTAssertNotNil(manager.plugin(id: "a"))
        XCTAssertNil(manager.plugin(id: "missing"))
        XCTAssertTrue(manager.isRegistered(id: "a"))
        XCTAssertFalse(manager.isRegistered(id: "missing"))
    }

    func testEnabledPluginsFiltering() throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let toggleable = FakePlugin(id: "toggleable")
        let required = FakePlugin(id: "required", policy: .required)
        try kernel.registerPlugin(toggleable)
        try kernel.registerPlugin(required)

        let filtered = manager.enabledPlugins(from: [toggleable, required])
        XCTAssertEqual(filtered.map(\.id), ["toggleable", "required"])
    }

    func testObserverReceivesEnabledStateChanges() async throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let a = FakePlugin(id: "a")
        try kernel.start(plugins: [a])

        var events: [PluginManagingEvent] = []
        let handle = manager.addPluginObserver { events.append($0) }

        // 禁用（policy 可配置 → 允许）。
        let disabled = await manager.disablePlugin(id: "a")
        XCTAssertTrue(disabled)
        XCTAssertTrue(events.contains {
            if case .enabledStateChanged(pluginID: "a", enabled: false) = $0 { return true }
            return false
        })

        let enabled = await manager.enablePlugin(id: "a")
        XCTAssertTrue(enabled)
        XCTAssertTrue(events.contains {
            if case .enabledStateChanged(pluginID: "a", enabled: true) = $0 { return true }
            return false
        })

        handle.cancel()
    }

    func testObserverHandleCancelStopsEvents() async throws {
        let kernel = KernelCoreContainer()
        let manager = DefaultPluginManager(kernel: kernel)
        let a = FakePlugin(id: "a")
        try kernel.registerPlugin(a)

        var count = 0
        let handle = manager.addPluginObserver { _ in count += 1 }
        handle.cancel()
        handle.cancel() // 重复 cancel 无副作用

        _ = await manager.disablePlugin(id: "a")
        XCTAssertEqual(count, 0)
    }

    func testKernelNotAttachedError() throws {
        let manager = DefaultPluginManager()
        XCTAssertThrowsError(try manager.unloadPlugin(id: "x")) { error in
            XCTAssertEqual(error as? PluginManagingError, .kernelNotAttached)
        }
    }
}
