@testable import PluginProjectPicker
import Testing

@Suite("PluginProjectPicker")
struct ProjectPickerPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(ProjectPickerPlugin.metadata.id == "ProjectPickerPlugin")
        #expect(ProjectPickerPlugin.metadata.iconName == "folder")
        #expect(ProjectPickerPlugin.metadata.allowUserToggle == false)
        #expect(ProjectPickerPlugin.metadata.defaultEnabled == true)
        #expect(ProjectPickerPlugin.metadata.tableName == "ProjectPicker")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(ProjectPickerPlugin.metadata.displayName.isEmpty == false)
        #expect(ProjectPickerPlugin.metadata.description.isEmpty == false)
    }

    @Test("toolbar contribution is available")
    func toolbarContribution() {
        #expect(ProjectPickerPlugin.shared.toolBarLeadingView() != nil)
    }
}
