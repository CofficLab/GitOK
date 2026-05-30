@testable import PluginGitPull
import Testing

@Suite("PluginGitPull")
struct GitPullPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitPullPlugin.metadata.id == "GitPullPlugin")
        #expect(GitPullPlugin.metadata.iconName == "arrow.down")
        #expect(GitPullPlugin.metadata.allowUserToggle == true)
        #expect(GitPullPlugin.metadata.defaultEnabled == true)
        #expect(GitPullPlugin.metadata.tableName == "GitPull")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(PluginGitPullLocalization.bundle.url(forResource: "GitPull", withExtension: "xcstrings") != nil)
        #expect(PluginGitPullLocalization.string("Pull from remote").isEmpty == false)
    }

    @Test("toolbar contribution is available")
    func toolbarContribution() {
        #expect(GitPullPlugin.shared.toolBarTrailingView() != nil)
    }
}
