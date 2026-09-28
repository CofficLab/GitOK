import Foundation
import Testing
@testable import PluginGitLFS
import KernelCore

@Suite("GitLFSPlugin Lifecycle")
@MainActor
struct GitLFSPluginLifecycleTests {

    @Test("onBoot with missing StatusBarProviding returns early")
    func onBootMissingStatusBar() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitLFSPlugin()
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onRegister/onUnregister with empty kernel are no-ops")
    func onRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitLFSPlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitLFSPlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
