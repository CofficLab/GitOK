import KernelCore
import XCTest
@testable import KitGitOKCore

@MainActor
final class GitOKKernelLifecycleTests: XCTestCase {
    private final class TestService {}

    private enum KernelPlugin: GitOKPlugin {
        static let metadata = GitOKPluginMetadata(
            id: "KernelPlugin",
            displayName: "Kernel Plugin",
            description: "",
            policy: .alwaysOn,
            tableName: "KitGitOKCore"
        )

        static func onBoot(
            kernel: KernelCoreContainer,
            dependencies: GitOKPluginDependencies
        ) {
            let service = TestService()
            try? kernel.registerProvider(TestService.self, service)
            dependencies.register(service, for: TestService.self)
        }
    }

    func testKernelFirstBootHookReceivesTheHostKernel() throws {
        let kernel = KernelCoreContainer()
        let runtime = GitOKPluginRuntime(settingsStore: PluginSettingsStore(userDefaults: .standard))
        runtime.register(KernelPlugin.self)

        for service in GitOKRequiredServices.all {
            final class RequiredService: NSObject {}
            try kernel.registerProvider(RequiredService(), for: service)
        }

        try runtime.startup(kernel: kernel)

        XCTAssertNotNil(kernel.resolveProvider(TestService.self))
    }
}
