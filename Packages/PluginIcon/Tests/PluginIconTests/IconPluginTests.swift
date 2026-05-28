@testable import PluginIcon
import Testing

@Suite("PluginIcon")
struct IconPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(IconPlugin.metadata.id == "IconPlugin")
        #expect(IconPlugin.metadata.iconName == "photo")
        #expect(IconPlugin.metadata.allowUserToggle == false)
        #expect(IconPlugin.metadata.defaultEnabled == true)
        #expect(IconPlugin.metadata.tableName == "Icon")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(IconPlugin.metadata.displayName.isEmpty == false)
        #expect(IconPlugin.metadata.description.isEmpty == false)
    }
}
