import XCTest
@testable import GitOKCoreKit

private struct RuntimeTestPlugin: SuperPlugin {
    let instanceLabel: String
    let pluginOrder: Int
    let pluginPolicy: GitOKPluginPolicy
    let tabName: String?

    var pluginDisplayName: String { instanceLabel }
    var pluginDescription: String { "" }
    var pluginIconName: String { "puzzlepiece.extension" }
    var pluginTableName: String { "GitOKCoreKitTests" }

    init(
        instanceLabel: String,
        pluginOrder: Int = 9999,
        pluginPolicy: GitOKPluginPolicy = .optOut,
        tabName: String? = nil
    ) {
        self.instanceLabel = instanceLabel
        self.pluginOrder = pluginOrder
        self.pluginPolicy = pluginPolicy
        self.tabName = tabName
    }

    func addTabItem() -> String? {
        tabName
    }
}

@MainActor
final class GitOKPluginRuntimeTests: XCTestCase {
    func testRegisteredPluginsAreSortedByOrder() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(instanceLabel: "last", pluginOrder: 20))
        runtime.register(RuntimeTestPlugin(instanceLabel: "first", pluginOrder: 10))

        XCTAssertEqual(runtime.plugins.map(\.instanceLabel), ["first", "last"])
        XCTAssertEqual(runtime.registeredCount, 2)
    }

    func testDefaultDisabledToggleablePluginIsFilteredFromTabs() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(
            instanceLabel: "disabled-by-default-\(UUID().uuidString)",
            pluginPolicy: .optIn,
            tabName: "Hidden"
        ))

        XCTAssertEqual(runtime.tabNames, [])
    }

    func testNonToggleablePluginIsAlwaysEnabled() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(
            instanceLabel: "forced-on-\(UUID().uuidString)",
            pluginPolicy: .alwaysOn,
            tabName: "Visible"
        ))

        XCTAssertEqual(runtime.tabNames, ["Visible"])
    }
}
