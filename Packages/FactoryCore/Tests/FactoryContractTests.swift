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
}
