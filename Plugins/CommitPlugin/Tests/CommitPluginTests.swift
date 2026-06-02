@testable import CommitPlugin
import Testing

@Suite("CommitPlugin")
struct CommitPluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(CommitPlugin.metadata.id == "CommitPlugin")
        #expect(CommitPlugin.metadata.iconName == "arrow.up.arrow.down")
        #expect(CommitPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(CommitPlugin.metadata.displayName.isEmpty == false)
        #expect(CommitPlugin.metadata.description.isEmpty == false)
    }
}
