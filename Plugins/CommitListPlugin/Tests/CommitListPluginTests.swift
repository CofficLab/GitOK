@testable import CommitListPlugin
import Testing

@Suite("CommitListPlugin")
struct CommitListPluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(CommitListPlugin.metadata.id == "CommitListPlugin")
        #expect(CommitListPlugin.metadata.iconName == "arrow.up.arrow.down")
        #expect(CommitListPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(CommitListPlugin.metadata.displayName.isEmpty == false)
        #expect(CommitListPlugin.metadata.description.isEmpty == false)
    }
}
