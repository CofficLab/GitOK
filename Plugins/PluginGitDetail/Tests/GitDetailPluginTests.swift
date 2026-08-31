@testable import GitDetailPlugin
import Testing

@Suite("GitDetailPlugin")
struct GitDetailPluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(GitDetailPlugin.metadata.id == "GitDetailPlugin")
        #expect(GitDetailPlugin.metadata.iconName == "doc.text.magnifyingglass")
        #expect(GitDetailPlugin.metadata.order == 120)
        #expect(GitDetailPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitDetailPlugin.metadata.displayName.isEmpty == false)
    }
}
