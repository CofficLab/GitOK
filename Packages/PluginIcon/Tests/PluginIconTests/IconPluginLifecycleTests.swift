import Foundation
import Testing
@testable import PluginIcon
import KernelCore

@Suite("IconPlugin Lifecycle")
@MainActor
struct IconPluginLifecycleTests {

    @Test("onBoot with missing providers returns early")
    func onBootMissingProviders() throws {
        let kernel = KernelCoreContainer()
        let plugin = IconPlugin()
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onRegister/onUnregister with empty kernel are no-ops")
    func onRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = IconPlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = IconPlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
