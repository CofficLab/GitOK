import XCTest
@testable import GitOKCoreKit

final class GitOKPluginLifecycleTests: XCTestCase {
    private final class TestService {}

    private enum LifecycleSpyPlugin: GitOKPlugin {
        nonisolated(unsafe) static var bootCalls = 0
        nonisolated(unsafe) static var readyCalls = 0

        static let metadata = GitOKPluginMetadata(
            id: "LifecycleSpyPlugin",
            displayName: "Lifecycle Spy",
            description: "",
            order: 200,
            policy: .alwaysOn,
            tableName: "GitOKCoreKit"
        )

        static func onBoot(_ dependencies: GitOKPluginDependencies) {
            bootCalls += 1
            dependencies.register(TestService(), for: TestService.self)
        }

        static func onReady(_ context: GitOKPluginContext) {
            readyCalls += 1
        }
    }

    override func setUp() {
        super.setUp()
        LifecycleSpyPlugin.bootCalls = 0
        LifecycleSpyPlugin.readyCalls = 0
    }

    @MainActor
    func testStartupRunsBootValidationAndReadyInOrder() throws {
        let runtime = GitOKPluginRuntime(settingsStore: makeSettingsStore())
        runtime.register(LifecycleSpyPlugin.self)
        let dependencies = GitOKPluginDependencies()
        registerRequiredServices(into: dependencies)

        try runtime.startup(dependencies: dependencies)

        XCTAssertEqual(LifecycleSpyPlugin.bootCalls, 1)
        XCTAssertEqual(LifecycleSpyPlugin.readyCalls, 1)
        XCTAssertNotNil(dependencies.resolve(TestService.self))
    }

    @MainActor
    func testStartupFailsLoudlyWhenRequiredServicesMissing() {
        let runtime = GitOKPluginRuntime(settingsStore: makeSettingsStore())
        runtime.register(LifecycleSpyPlugin.self)
        let dependencies = GitOKPluginDependencies()

        XCTAssertThrowsError(try runtime.startup(dependencies: dependencies)) { error in
            guard case GitOKCoreKitError.missingRequiredServices(let names) = error else {
                return XCTFail("expected missingRequiredServices, got \(error)")
            }
            XCTAssertFalse(names.isEmpty)
            XCTAssertTrue(names.contains("GitOKGitCommandServicing"))
        }
        // onReady must not run when validation failed
        XCTAssertEqual(LifecycleSpyPlugin.readyCalls, 0)
    }

    @MainActor
    private func makeSettingsStore() -> PluginSettingsStore {
        let suiteName = "GitOKPluginLifecycleTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        return PluginSettingsStore(userDefaults: userDefaults)
    }

    @MainActor
    private func registerRequiredServices(into dependencies: GitOKPluginDependencies) {
        final class Service: NSObject {}
        dependencies.register(Service(), for: GitOKRepositoryServicing.self)
        dependencies.register(Service(), for: GitOKActivityServicing.self)
        dependencies.register(Service(), for: GitOKGitCommandServicing.self)
        dependencies.register(Service(), for: GitOKThemeServicing.self)
        dependencies.register(Service(), for: GitOKNavigationServicing.self)
    }
}
