import Foundation
import Testing
@testable import PluginGitCommitStyleSettings
import KernelCore

@Suite("GitCommitStyleSettingsPlugin Lifecycle")
@MainActor
struct GitCommitStyleSettingsPluginLifecycleTests {

    @Test("onBoot with missing SettingViewProviding returns early")
    func onBootMissingSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onRegister/onUnregister with empty kernel are no-ops")
    func onRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = GitCommitStyleSettingsPlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
