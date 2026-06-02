@testable import GitSyncPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitSyncPlugin")
struct GitSyncPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitSyncPlugin.metadata.id == "SyncPlugin")
        #expect(GitSyncPlugin.metadata.iconName == "arrow.clockwise")
        #expect(GitSyncPlugin.metadata.order == 9999)
        #expect(GitSyncPlugin.metadata.tableName == "Localizable")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(GitSyncPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings") != nil)
        #expect(GitSyncPluginLocalization.string("Sync with remote repository").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    @MainActor
    func toolbarContribution() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitSyncPlugin.shared.toolBarTrailingView(context: context) != nil)
    }
}
