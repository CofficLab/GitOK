import Foundation
import KernelCore
import XCTest
@testable import ProviderPluginControl

@MainActor
final class PluginControllingTests: XCTestCase {
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

    func testIsEnabledReflectsKernelState() throws {
        let kernel = KernelCoreContainer()
        let controlling = DefaultPluginControlling(kernel: kernel)
        let plugin = FakePlugin()
        try kernel.registerPlugin(plugin)
        XCTAssertTrue(controlling.isEnabled(id: plugin.id))
    }

    func testControlWithoutAttachedKernelReturnsFalse() async {
        let controlling = DefaultPluginControlling()
        let result = await controlling.enablePlugin(id: "whatever")
        XCTAssertFalse(result)
        XCTAssertNotNil(controlling.lastErrorDescription)
    }
}
