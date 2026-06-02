@testable import BannerPlugin
import Testing

@Suite("BannerPlugin")
struct BannerPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(BannerPlugin.metadata.id == "BannerPlugin")
        #expect(BannerPlugin.metadata.iconName == "puzzlepiece.extension")
        #expect(BannerPlugin.metadata.order == 2)
        #expect(BannerPlugin.metadata.allowUserToggle == false)
        #expect(BannerPlugin.metadata.defaultEnabled == false)
        #expect(BannerPlugin.metadata.tableName == "Banner")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(BannerPlugin.metadata.displayName.isEmpty == false)
    }
}
