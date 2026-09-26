import Foundation
import Testing
@testable import PluginProjectLanguages
import KernelCore

@Suite("ProjectLanguagesPlugin Lifecycle")
@MainActor
struct ProjectLanguagesPluginLifecycleTests {

    @Test("onBoot with missing ProjectProviding returns early")
    func onBootMissingProjects() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectLanguagesPlugin()
        try plugin.onBoot(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = ProjectLanguagesPlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
