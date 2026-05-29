@testable import PluginSmartMerge
import Testing

@Suite("PluginSmartMerge")
struct SmartMergePluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(SmartMergePlugin.metadata.id == "SmartMergePlugin")
        #expect(SmartMergePlugin.metadata.iconName == "arrow.merge")
        #expect(SmartMergePlugin.metadata.allowUserToggle == true)
        #expect(SmartMergePlugin.metadata.defaultEnabled == true)
        #expect(SmartMergePlugin.metadata.tableName == "GitMerge")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(SmartMergePlugin.metadata.displayName.isEmpty == false)
        #expect(SmartMergePlugin.metadata.description.isEmpty == false)
    }
}
