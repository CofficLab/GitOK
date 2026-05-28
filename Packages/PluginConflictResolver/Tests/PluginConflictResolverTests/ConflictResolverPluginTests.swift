@testable import PluginConflictResolver
import Testing

@Suite("PluginConflictResolver")
struct ConflictResolverPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(ConflictResolverPlugin.metadata.id == "ConflictResolverPlugin")
        #expect(ConflictResolverPlugin.metadata.iconName == "exclamationmark.triangle")
        #expect(ConflictResolverPlugin.metadata.allowUserToggle == false)
        #expect(ConflictResolverPlugin.metadata.defaultEnabled == true)
        #expect(ConflictResolverPlugin.metadata.tableName == "GitConflictResolver")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(ConflictResolverPlugin.metadata.displayName.isEmpty == false)
        #expect(ConflictResolverPlugin.metadata.description.isEmpty == false)
    }
}
