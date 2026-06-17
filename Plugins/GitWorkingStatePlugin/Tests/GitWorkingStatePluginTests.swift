@testable import GitWorkingStatePlugin
import Testing

@Suite("GitWorkingStatePlugin")
struct GitWorkingStatePluginTests {
    @Test("metadata matches plugin identity")
    func metadata() {
        #expect(GitWorkingStatePlugin.metadata.id == "GitWorkingStatePlugin")
        #expect(GitWorkingStatePlugin.metadata.iconName == "tray.2")
        #expect(GitWorkingStatePlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitWorkingStatePlugin.metadata.displayName.isEmpty == false)
        #expect(GitWorkingStatePlugin.metadata.description.isEmpty == false)
    }
}
