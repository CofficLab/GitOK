import XCTest
@testable import GitOKCoreKit

private struct RuntimeTestPlugin: SuperPlugin {
    let instanceLabel: String
    let pluginOrder: Int
    let pluginAllowUserToggle: Bool
    let pluginDefaultEnabled: Bool
    let tabName: String?

    var pluginDisplayName: String { instanceLabel }
    var pluginDescription: String { "" }
    var pluginIconName: String { "puzzlepiece.extension" }
    var pluginTableName: String { "GitOKCoreKitTests" }

    init(
        instanceLabel: String,
        pluginOrder: Int = 9999,
        pluginAllowUserToggle: Bool = true,
        pluginDefaultEnabled: Bool = true,
        tabName: String? = nil
    ) {
        self.instanceLabel = instanceLabel
        self.pluginOrder = pluginOrder
        self.pluginAllowUserToggle = pluginAllowUserToggle
        self.pluginDefaultEnabled = pluginDefaultEnabled
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
            pluginDefaultEnabled: false,
            tabName: "Hidden"
        ))

        XCTAssertEqual(runtime.tabNames, [])
    }

    func testNonToggleablePluginIsAlwaysEnabled() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(
            instanceLabel: "forced-on-\(UUID().uuidString)",
            pluginAllowUserToggle: false,
            pluginDefaultEnabled: false,
            tabName: "Visible"
        ))

        XCTAssertEqual(runtime.tabNames, ["Visible"])
    }
}
