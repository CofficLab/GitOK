import KitGitOKCore
import KernelCore
import ProviderProject
import XCTest
@testable import FactoryCore

@MainActor
final class FactoryContractTests: XCTestCase {
    func testAppBootstrapIdentifiersRemainStable() {
        XCTAssertEqual(AppBootstrap.mainWindowID, "gitok.main")
        XCTAssertEqual(AppBootstrap.settingsWindowID, "gitok.settings")
    }

    func testDefaultProviderFactoryIsAvailable() {
        _ = DefaultProviderFactory()
        _ = DefaultViewFactory()
    }

    func testRootContainerRegistersTypedProviderGraph() {
        let root = RootContainer(composition: .init())

        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKProjectServicing).self))
        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKRepositoryServicing).self))
        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKActivityServicing).self))
        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKGitCommandServicing).self))
        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKThemeServicing).self))
        XCTAssertNotNil(root.kernel.resolveProvider((any GitOKNavigationServicing).self))
    }
}
