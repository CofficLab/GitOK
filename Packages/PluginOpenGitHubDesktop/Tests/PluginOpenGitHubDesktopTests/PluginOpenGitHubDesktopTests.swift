import Foundation
import KitOpenIn
import Testing
@testable import PluginOpenGitHubDesktop

@Suite("PluginOpenGitHubDesktop")
@MainActor
struct PluginOpenGitHubDesktopTests {

    @Test("plugin identity derives from githubDesktop target")
    func identity() {
        let plugin = OpenGitHubDesktopPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.open-githubDesktop")
        #expect(plugin.target == .githubDesktop)
        #expect(plugin.metadata.category == .project)
        #expect(plugin.order == OpenTarget.githubDesktop.toolbarOrder)
    }

    @Test("githubDesktop target display values")
    func targetValues() {
        #expect(OpenTarget.githubDesktop.displayName == "GitHub Desktop")
        #expect(OpenTarget.githubDesktop.systemImage == "arrow.triangle.branch")
        #expect(OpenTarget.githubDesktop.isAlwaysAvailable == false)
        #expect(OpenTarget.githubDesktop.toolbarOrder == 80)
    }
}
