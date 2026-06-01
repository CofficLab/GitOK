@testable import PluginGitSync
import Foundation
import GitOKCoreKit
import Testing

@Suite("PluginGitSync")
struct GitSyncPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitSyncPlugin.metadata.id == "SyncPlugin")
        #expect(GitSyncPlugin.metadata.iconName == "arrow.clockwise")
        #expect(GitSyncPlugin.metadata.order == 9999)
        #expect(GitSyncPlugin.metadata.allowUserToggle == true)
        #expect(GitSyncPlugin.metadata.defaultEnabled == true)
        #expect(GitSyncPlugin.metadata.tableName == "GitSync")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(PluginGitSyncLocalization.bundle.url(forResource: "GitSync", withExtension: "xcstrings") != nil)
        #expect(PluginGitSyncLocalization.string("Sync with remote repository").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    @MainActor
    func toolbarContribution() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitSyncPlugin.shared.toolBarTrailingView(context: context) != nil)
    }
}
