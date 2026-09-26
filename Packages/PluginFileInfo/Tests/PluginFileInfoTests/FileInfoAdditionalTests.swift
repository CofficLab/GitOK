import Foundation
import Testing
@testable import PluginFileInfo
import KernelCore

@Suite("FileInfo Additional Coverage")
@MainActor
struct FileInfoAdditionalTests {

    @Test("onBoot with missing StatusBarProviding returns early")
    func onBootMissingStatusBar() throws {
        let kernel = KernelCoreContainer()
        let plugin = FileInfoPlugin()
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onRegister/onUnregister with empty kernel are no-ops")
    func onRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = FileInfoPlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = FileInfoPlugin()
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("localization passthrough returns non-empty string")
    func localizationPassthrough() {
        let result = FileInfoLocalization.string("File Info", bundle: Bundle.module)
        #expect(!result.isEmpty)
    }
}
