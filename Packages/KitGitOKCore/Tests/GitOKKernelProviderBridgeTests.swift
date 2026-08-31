import KernelCore
import XCTest
@testable import KitGitOKCore

@MainActor
final class GitOKKernelProviderBridgeTests: XCTestCase {
    private protocol TestProviding: AnyObject {}

    private final class TestProvider: NSObject, TestProviding {}

    func testLegacyRegistrationIsVisibleThroughKernelAndContext() {
        let kernel = KernelCoreContainer()
        let dependencies = GitOKPluginDependencies(kernel: kernel)
        let provider = TestProvider()

        dependencies.register(provider, for: TestProviding.self)

        let context = GitOKPluginContext(kernel: kernel, dependencies: dependencies)

        XCTAssertTrue(kernel.resolveProvider(TestProviding.self) === provider)
        XCTAssertTrue(context.resolve(TestProviding.self) === provider)
        XCTAssertTrue(dependencies.resolveAny(TestProviding.self) === provider)
    }
}
