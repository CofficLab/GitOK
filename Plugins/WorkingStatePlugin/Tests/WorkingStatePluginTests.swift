@testable import WorkingStatePlugin
import Testing

@Suite("WorkingStatePlugin")
struct WorkingStatePluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(WorkingStatePlugin.metadata.id == "WorkingStatePlugin")
        #expect(WorkingStatePlugin.metadata.iconName == "tray.2")
        #expect(WorkingStatePlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(WorkingStatePlugin.metadata.displayName.isEmpty == false)
        #expect(WorkingStatePlugin.metadata.description.isEmpty == false)
    }
}
