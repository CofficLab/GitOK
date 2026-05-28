@testable import PluginCommit
import Testing

@Suite("PluginCommit")
struct CommitPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(CommitPlugin.metadata.id == "CommitPlugin")
        #expect(CommitPlugin.metadata.iconName == "arrow.up.arrow.down")
        #expect(CommitPlugin.metadata.allowUserToggle == false)
        #expect(CommitPlugin.metadata.defaultEnabled == true)
        #expect(CommitPlugin.metadata.tableName == "GitCommit")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(CommitPlugin.metadata.displayName.isEmpty == false)
        #expect(CommitPlugin.metadata.description.isEmpty == false)
    }
}
