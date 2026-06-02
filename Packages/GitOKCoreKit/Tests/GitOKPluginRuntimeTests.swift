import XCTest
@testable import GitOKCoreKit

private struct RuntimeTestPlugin: SuperPlugin {
    let instanceLabel: String
    let pluginOrder: Int

    var pluginDisplayName: String { instanceLabel }
    var pluginDescription: String { "" }
    var pluginIconName: String { "puzzlepiece.extension" }
    var pluginTableName: String { "GitOKCoreKitTests" }

    init(
        instanceLabel: String,
        pluginOrder: Int = 9999
    ) {
        self.instanceLabel = instanceLabel
        self.pluginOrder = pluginOrder
    }
}

@MainActor
final class GitOKPluginRuntimeTests: XCTestCase {
    func testRegisteredPluginsAreSortedByOrder() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(instanceLabel: "last", pluginOrder: 20))
        runtime.register(RuntimeTestPlugin(instanceLabel: "first", pluginOrder: 10))

        XCTAssertEqual(runtime.registeredPluginLabels, ["first", "last"])
        XCTAssertEqual(runtime.registeredCount, 2)
    }
}
