import XCTest
@testable import ProviderToast

@MainActor
final class DefaultToastProvidingAdditionalTests: XCTestCase {
    func testPresentErrorIsNoOp() {
        let provider = DefaultToastProviding()
        provider.presentError(title: "title", message: "message")
    }

    func testDismissErrorIsNoOp() {
        let provider = DefaultToastProviding()
        provider.dismissError()
    }

    func testLumiErrorNoticeEquality() {
        let id = UUID()
        let a = LumiErrorNotice(id: id, title: "t", message: "m")
        let b = LumiErrorNotice(id: id, title: "t", message: "m")
        XCTAssertEqual(a, b)

        let c = LumiErrorNotice(title: "t", message: "m")
        XCTAssertNotEqual(a, c)
    }

    func testLumiToastStyleValues() {
        XCTAssertEqual(LumiToastStyle.info.rawValue, "info")
        XCTAssertEqual(LumiToastStyle.success.rawValue, "success")
        XCTAssertEqual(LumiToastStyle.warning.rawValue, "warning")
        XCTAssertEqual(LumiToastStyle.error.rawValue, "error")
    }
}
