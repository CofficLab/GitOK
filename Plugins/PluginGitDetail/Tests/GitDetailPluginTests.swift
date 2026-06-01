@testable import PluginGitDetail
import Testing

@Suite("PluginGitDetail")
struct GitDetailPluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(GitDetailPlugin.metadata.id == "GitDetailPlugin")
        #expect(GitDetailPlugin.metadata.iconName == "puzzlepiece.extension")
        #expect(GitDetailPlugin.metadata.order == 0)
        #expect(GitDetailPlugin.metadata.allowUserToggle == false)
        #expect(GitDetailPlugin.metadata.defaultEnabled == false)
        #expect(GitDetailPlugin.metadata.tableName == "GitDetail")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitDetailPlugin.metadata.displayName.isEmpty == false)
    }
}
