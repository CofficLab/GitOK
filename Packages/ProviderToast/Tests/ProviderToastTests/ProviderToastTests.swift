import Foundation
import XCTest
@testable import ProviderToast

@MainActor
final class ProviderToastTests: XCTestCase {
    /// 测试用实现：记录收到的 Toast。
    private final class RecordingToastProvider: ToastProviding {
        var received: [LumiToast] = []
        var receivedErrors: [LumiErrorNotice] = []

        func show(_ toast: LumiToast) {
            received.append(toast)
        }

        func presentError(title: String, message: String) {
            receivedErrors.append(LumiErrorNotice(title: title, message: message))
        }

        func dismissError() {}
    }

    func testToastValueSemantics() {
        let a = LumiToast(title: "hi", detail: "d", style: .warning, duration: 2)
        let b = LumiToast(title: "hi", detail: "d", style: .warning, duration: 2)
        let c = LumiToast(title: "hi", detail: "d", style: .error, duration: 2)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a.style, .warning)
    }

    func testConvenienceShowBuildsToast() {
        let provider = RecordingToastProvider()

        provider.show("保存成功", style: .success)

        XCTAssertEqual(provider.received.count, 1)
        XCTAssertEqual(provider.received[0].title, "保存成功")
        XCTAssertNil(provider.received[0].detail)
        XCTAssertEqual(provider.received[0].style, .success)
        XCTAssertNil(provider.received[0].duration)
    }

    func testProviderAccessibleThroughProtocol() {
        let provider: any ToastProviding = RecordingToastProvider()

        provider.show(LumiToast(title: "hello"))

        let recording = provider as! RecordingToastProvider
        XCTAssertEqual(recording.received.count, 1)
        XCTAssertEqual(recording.received[0].title, "hello")
    }

    func testPersistentErrorIsAvailableThroughProtocol() {
        let provider = RecordingToastProvider()

        provider.presentError(title: "Pull failed", message: "hint: divergent branches")

        XCTAssertEqual(provider.receivedErrors.count, 1)
        XCTAssertEqual(provider.receivedErrors[0].title, "Pull failed")
        XCTAssertEqual(provider.receivedErrors[0].message, "hint: divergent branches")
    }

    // MARK: - DefaultToastProviding

    func testDefaultToastProvidingIsNoOp() {
        let provider: any ToastProviding = DefaultToastProviding()

        // 不应抛错、不应崩溃（契约：非阻塞、不抛错）
        provider.show("hello")
        provider.show(LumiToast(title: "hello", detail: "d", style: .error))
    }
}
