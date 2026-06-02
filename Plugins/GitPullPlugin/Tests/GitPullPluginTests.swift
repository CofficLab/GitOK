@testable import GitPullPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitPullPlugin")
struct GitPullPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitPullPlugin.metadata.id == "GitPullPlugin")
        #expect(GitPullPlugin.metadata.iconName == "arrow.down")
        #expect(GitPullPlugin.metadata.tableName == "Localizable")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(GitPullPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings") != nil)
        #expect(GitPullPluginLocalization.string("Pull from remote").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    @MainActor
    func toolbarContribution() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitPullPlugin.shared.toolBarTrailingView(context: context) != nil)
    }
}
