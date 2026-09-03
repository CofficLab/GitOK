import Foundation
import KernelCore
import Testing
@testable import PluginLicense

@Suite("PluginLicense")
@MainActor
struct PluginLicenseTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = LicensePlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.license")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
