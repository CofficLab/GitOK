@testable import IconPlugin
import Testing

@Suite("IconPlugin")
struct IconPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(IconPlugin.metadata.id == "IconPlugin")
        #expect(IconPlugin.metadata.iconName == "photo")
        #expect(IconPlugin.metadata.allowUserToggle == false)
        #expect(IconPlugin.metadata.defaultEnabled == false)
        #expect(IconPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(IconPlugin.metadata.displayName.isEmpty == false)
        #expect(IconPlugin.metadata.description.isEmpty == false)
    }
}
