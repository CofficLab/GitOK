@testable import PluginCleanStatus
import Testing

@Suite("PluginCleanStatus")
struct CleanStatusPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(CleanStatusPlugin.metadata.id == "CleanStatusPlugin")
        #expect(CleanStatusPlugin.metadata.iconName == "checkmark.circle")
        #expect(CleanStatusPlugin.metadata.order == 24)
        #expect(CleanStatusPlugin.metadata.allowUserToggle == false)
        #expect(CleanStatusPlugin.metadata.defaultEnabled == true)
        #expect(CleanStatusPlugin.metadata.tableName == "CleanStatus")
    }

    @Test("localized description resolves")
    func localizedDescription() {
        #expect(CleanStatusPlugin.metadata.description.isEmpty == false)
    }
}
