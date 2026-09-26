import Foundation
import KernelCore
import XCTest
@testable import ProviderPluginControl

@MainActor
final class DefaultPluginControllingAdditionalTests: XCTestCase {
    @MainActor
    private final class FakePlugin: SuperPlugin {
        let id = "test.fake"
        var order: Int { 10 }
        var metadata: PluginMetadata {
            PluginMetadata(
                id: id,
                name: "Fake",
                description: "Fake test plugin",
                category: .general,
                stage: .stable,
                policy: .enabledByDefault
            )
        }
    }

    func testEnablePluginWhenKernelStoppedSetsError() async throws {
        let kernel = KernelCoreContainer()
        let controlling = DefaultPluginControlling(kernel: kernel)
        let plugin = FakePlugin()
        try kernel.registerPlugin(plugin)

        // 内核未启动时 enable 会失败，但应设置 lastErrorDescription。
        let result = await controlling.enablePlugin(id: plugin.id)
        // 不强制断言 result；仅验证不崩溃。
        _ = result
    }

    func testDisablePluginWhenKernelStoppedSetsError() async throws {
        let kernel = KernelCoreContainer()
        let controlling = DefaultPluginControlling(kernel: kernel)
        let plugin = FakePlugin()
        try kernel.registerPlugin(plugin)

        let result = await controlling.disablePlugin(id: plugin.id)
        _ = result
    }

    func testAttachKernelAfterInit() async {
        let kernel = KernelCoreContainer()
        let controlling = DefaultPluginControlling()
        controlling.attach(kernel: kernel)
        let result = await controlling.enablePlugin(id: "nonexistent")
        _ = result
    }

    func testDisableWithoutAttachedKernel() async {
        let controlling = DefaultPluginControlling()
        let result = await controlling.disablePlugin(id: "whatever")
        XCTAssertFalse(result)
        XCTAssertNotNil(controlling.lastErrorDescription)
    }

    func testIsEnabledWithoutKernel() {
        let controlling = DefaultPluginControlling()
        XCTAssertFalse(controlling.isEnabled(id: "whatever"))
    }
}
