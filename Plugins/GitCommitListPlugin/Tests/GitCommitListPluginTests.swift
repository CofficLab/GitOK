@testable import GitCommitListPlugin
import Testing

@Suite("GitCommitListPlugin")
struct GitCommitListPluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(GitCommitListPlugin.metadata.id == "GitCommitListPlugin")
        #expect(GitCommitListPlugin.metadata.iconName == "arrow.up.arrow.down")
        #expect(GitCommitListPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitCommitListPlugin.metadata.displayName.isEmpty == false)
        #expect(GitCommitListPlugin.metadata.description.isEmpty == false)
    }
}
