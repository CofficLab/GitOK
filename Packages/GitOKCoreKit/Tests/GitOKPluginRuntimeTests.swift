import XCTest
@testable import GitOKCoreKit

private enum FirstTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "first",
        displayName: "first",
        order: 10,
        policy: .alwaysOn
    )

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

private enum LastTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "last",
        displayName: "last",
        order: 20,
        policy: .alwaysOn
    )

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

private enum AlwaysOnTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(id: "alwaysOn", displayName: "alwaysOn", policy: .alwaysOn)

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

private enum OptOutTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(id: "optOut", displayName: "optOut", policy: .optOut)

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

private enum OptInTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(id: "optIn", displayName: "optIn", policy: .optIn)

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

private enum DisabledTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(id: "disabled", displayName: "disabled", policy: .disabled)

    @MainActor
    static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

@MainActor
final class GitOKPluginRuntimeTests: XCTestCase {
    func testRegisteredPluginsAreSortedByOrder() {
        let runtime = GitOKPluginRuntime()

        runtime.register(LastTestPlugin.self)
        runtime.register(FirstTestPlugin.self)

        XCTAssertEqual(runtime.registeredPluginLabels, ["first", "last"])
        XCTAssertEqual(runtime.registeredCount, 2)
    }

    func testRuntimeRespectsPluginPolicyDefaults() {
        let runtime = GitOKPluginRuntime()

        runtime.register(AlwaysOnTestPlugin.self)
        runtime.register(OptOutTestPlugin.self)
        runtime.register(OptInTestPlugin.self)
        runtime.register(DisabledTestPlugin.self)

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

        runtime.register(AlwaysOnTestPlugin.self)
        runtime.register(OptOutTestPlugin.self)
        runtime.register(OptInTestPlugin.self)
        runtime.register(DisabledTestPlugin.self)

        XCTAssertEqual(runtime.tabNames, ["alwaysOn", "optIn"])
    }
}
