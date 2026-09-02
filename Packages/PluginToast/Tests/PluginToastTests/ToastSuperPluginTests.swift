import KernelCore
import ProviderRootView
import ProviderToast
import XCTest
@testable import PluginToast

@MainActor
final class ToastSuperPluginTests: XCTestCase {
    func testToastPluginReplacesTheDefaultProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any ToastProviding).self, DefaultToastProviding())

        let plugin = ToastSuperPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(kernel.resolveProvider((any ToastProviding).self) === plugin.center)
    }

    func testToastPluginMountsOverlayOnRootView() throws {
        let kernel = KernelCoreContainer()
        let rootView = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, rootView)

        let plugin = ToastSuperPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(rootView.overlays.contains { $0.id == ToastSuperPlugin.overlayID })

        try plugin.onShutdown(kernel: kernel)
        XCTAssertFalse(rootView.overlays.contains { $0.id == ToastSuperPlugin.overlayID })
    }

    func testDismissClearsTheCurrentToast() {
        let center = ToastCenter()
        center.show(LumiToast(title: "Saved", style: .success))
        XCTAssertEqual(center.currentToast?.title, "Saved")
        center.dismiss()
        XCTAssertNil(center.currentToast)
    }
}
