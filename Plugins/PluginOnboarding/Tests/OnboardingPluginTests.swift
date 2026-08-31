import XCTest
@testable import OnboardingPlugin

final class OnboardingPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(OnboardingPlugin.metadata.id, "OnboardingPlugin")
    }
}
