import XCTest
@testable import PluginSidebarToggle
import KernelCore

@MainActor
final class SidebarTogglePluginLifecycleTests: XCTestCase {
    func testOnBootMissingToolbar() throws {
        let kernel = KernelCoreContainer()
        let plugin = SidebarTogglePlugin()
        try plugin.onBoot(kernel: kernel)
    }

    func testOnRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = SidebarTogglePlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    func testOnShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = SidebarTogglePlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
