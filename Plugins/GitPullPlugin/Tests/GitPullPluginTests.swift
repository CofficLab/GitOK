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
        #expect(GitPullPlugin.metadata.allowUserToggle == false)
        #expect(GitPullPlugin.metadata.defaultEnabled == false)
        #expect(GitPullPlugin.metadata.tableName == "GitPull")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(GitPullPluginLocalization.bundle.url(forResource: "GitPull", withExtension: "xcstrings") != nil)
        #expect(GitPullPluginLocalization.string("Pull from remote").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    @MainActor
    func toolbarContribution() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitPullPlugin.shared.toolBarTrailingView(context: context) != nil)
    }
}
