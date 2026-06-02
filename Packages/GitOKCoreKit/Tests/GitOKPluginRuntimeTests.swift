import XCTest
@testable import GitOKCoreKit

private struct RuntimeTestPlugin: SuperPlugin {
    let instanceLabel: String
    let pluginOrder: Int
    let pluginPolicy: GitOKPluginPolicy

    var pluginDisplayName: String { instanceLabel }
    var pluginDescription: String { "" }
    var pluginIconName: String { "puzzlepiece.extension" }
    var pluginTableName: String { "GitOKCoreKitTests" }

    init(
        instanceLabel: String,
        pluginOrder: Int = 9999,
        pluginPolicy: GitOKPluginPolicy = .alwaysOn
    ) {
        self.instanceLabel = instanceLabel
        self.pluginOrder = pluginOrder
        self.pluginPolicy = pluginPolicy
    }

    func addTabItem() -> String? {
        instanceLabel
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

    func testRuntimeRespectsPluginPolicyDefaults() {
        let runtime = GitOKPluginRuntime()

        runtime.register(RuntimeTestPlugin(instanceLabel: "alwaysOn", pluginPolicy: .alwaysOn))
        runtime.register(RuntimeTestPlugin(instanceLabel: "optOut", pluginPolicy: .optOut))
        runtime.register(RuntimeTestPlugin(instanceLabel: "optIn", pluginPolicy: .optIn))
        runtime.register(RuntimeTestPlugin(instanceLabel: "disabled", pluginPolicy: .disabled))

        XCTAssertEqual(runtime.tabNames, ["alwaysOn", "optOut"])
    }

    func testRuntimeRespectsUserPluginSettingsForConfigurablePolicies() {
        let suiteName = "GitOKPluginRuntimeTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = PluginSettingsStore(userDefaults: userDefaults)
        settingsStore.setPluginEnabled("optOut", enabled: false)
        settingsStore.setPluginEnabled("optIn", enabled: true)

        let runtime = GitOKPluginRuntime(settingsStore: settingsStore)

        runtime.register(RuntimeTestPlugin(instanceLabel: "alwaysOn", pluginPolicy: .alwaysOn))
        runtime.register(RuntimeTestPlugin(instanceLabel: "optOut", pluginPolicy: .optOut))
        runtime.register(RuntimeTestPlugin(instanceLabel: "optIn", pluginPolicy: .optIn))
        runtime.register(RuntimeTestPlugin(instanceLabel: "disabled", pluginPolicy: .disabled))

        XCTAssertEqual(runtime.tabNames, ["alwaysOn", "optIn"])
    }
}
