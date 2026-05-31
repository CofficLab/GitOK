@testable import PluginAutoPush
import Testing

@Suite("PluginAutoPush")
struct AutoPushPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(AutoPushPlugin.metadata.id == "AutoPushPlugin")
        #expect(AutoPushPlugin.metadata.iconName == "arrow.up.circle")
        #expect(AutoPushPlugin.metadata.allowUserToggle == true)
        #expect(AutoPushPlugin.metadata.defaultEnabled == false)
        #expect(AutoPushPlugin.metadata.tableName == "AutoPush")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(PluginAutoPushLocalization.bundle.url(forResource: "AutoPush", withExtension: "xcstrings") != nil)
        #expect(PluginAutoPushLocalization.string("Auto Push").isEmpty == false)
    }
}
