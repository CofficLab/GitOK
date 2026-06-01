@testable import PluginGitPull
import Foundation
import GitOKCoreKit
import Testing

@Suite("PluginGitPull")
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
        #expect(PluginGitPullLocalization.bundle.url(forResource: "GitPull", withExtension: "xcstrings") != nil)
        #expect(PluginGitPullLocalization.string("Pull from remote").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    @MainActor
    func toolbarContribution() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitPullPlugin.shared.toolBarTrailingView(context: context) != nil)
    }
}
