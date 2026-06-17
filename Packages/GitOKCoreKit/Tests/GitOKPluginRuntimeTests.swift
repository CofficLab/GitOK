import SwiftUI
import XCTest
@testable import GitOKCoreKit

private enum DetailTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "detailTest",
        displayName: "detailTest",
        description: "",
        policy: .alwaysOn,
        tableName: "Localizable"
    )

    @MainActor
    static func detailPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [DetailPane] {
        guard tab == .git, context.isGitRepository else { return [] }
        return [DetailPane(id: metadata.id, view: AnyView(Text("git-detail")))]
    }
}

private enum AlwaysOnTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "alwaysOn",
        displayName: "alwaysOn",
        description: "",
        policy: .alwaysOn,
        tableName: "Localizable"
    )
}

private enum OptOutDetailPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "optOut",
        displayName: "optOut",
        description: "",
        policy: .optOut,
        tableName: "Localizable"
    )

    @MainActor
    static func detailPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [DetailPane] {
        [DetailPane(id: metadata.id, view: AnyView(Text("opt-out-detail")))]
    }
}

private enum OptInDetailPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "optIn",
        displayName: "optIn",
        description: "",
        policy: .optIn,
        tableName: "Localizable"
    )

    @MainActor
    static func detailPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [DetailPane] {
        [DetailPane(id: metadata.id, view: AnyView(Text("opt-in-detail")))]
    }
}

private enum OptOutTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "optOut",
        displayName: "optOut",
        description: "",
        policy: .optOut,
        tableName: "Localizable"
    )
}

private enum OptInTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "optIn",
        displayName: "optIn",
        description: "",
        policy: .optIn,
        tableName: "Localizable"
    )
}

private enum DisabledTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "disabled",
        displayName: "disabled",
        description: "",
        policy: .disabled,
        tableName: "Localizable"
    )
}

private enum FirstTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "first",
        displayName: "first",
        description: "",
        order: 10,
        policy: .alwaysOn,
        tableName: "Localizable"
    )
}

private enum LastTestPlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "last",
        displayName: "last",
        description: "",
        order: 20,
        policy: .alwaysOn,
        tableName: "Localizable"
    )
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

        XCTAssertEqual(
            Set(runtime.configurablePlugins.map(\.id)),
            Set(["alwaysOn", "optOut", "optIn"])
        )
    }

    func testRuntimeRespectsUserPluginSettingsForConfigurablePolicies() {
        let suiteName = "GitOKPluginRuntimeTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = PluginSettingsStore(userDefaults: userDefaults)
        settingsStore.setPluginEnabled("optOut", enabled: false)
        settingsStore.setPluginEnabled("optIn", enabled: true)

        let runtime = GitOKPluginRuntime(settingsStore: settingsStore)
        let context = GitOKPluginContext(isGitRepository: true)

        runtime.register(OptOutDetailPlugin.self)
        XCTAssertNil(runtime.enabledDetailView(for: .git, context: context))

        runtime.clearRegisteredPlugins()
        runtime.register(OptInDetailPlugin.self)
        XCTAssertNotNil(runtime.enabledDetailView(for: .git, context: context))
    }

    func testConfigurablePluginsListsAllRegisteredPluginsExceptDisabled() {
        let runtime = GitOKPluginRuntime()

        runtime.register(AlwaysOnTestPlugin.self)
        runtime.register(OptOutTestPlugin.self)
        runtime.register(OptInTestPlugin.self)
        runtime.register(DisabledTestPlugin.self)

        XCTAssertEqual(
            Set(runtime.configurablePlugins.map(\.id)),
            Set(["alwaysOn", "optOut", "optIn"])
        )
    }

    func testEnabledDetailViewRequiresMatchingTabAndGitRepository() {
        let runtime = GitOKPluginRuntime()
        runtime.register(DetailTestPlugin.self)

        let nonGitContext = GitOKPluginContext(isGitRepository: false)
        XCTAssertNil(runtime.enabledDetailView(for: .git, context: nonGitContext))

        let gitContext = GitOKPluginContext(isGitRepository: true)
        XCTAssertNotNil(runtime.enabledDetailView(for: .git, context: gitContext))
        XCTAssertNil(runtime.enabledDetailView(for: .banner, context: gitContext))
    }
}
