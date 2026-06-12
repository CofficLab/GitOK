@testable import ProjectPickerPlugin
import GitOKCoreKit
import Testing

@Suite("ProjectPickerPlugin")
struct ProjectPickerPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(ProjectPickerPlugin.metadata.id == "ProjectPickerPlugin")
        #expect(ProjectPickerPlugin.metadata.iconName == "folder")
        #expect(ProjectPickerPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(ProjectPickerPlugin.metadata.displayName.isEmpty == false)
        #expect(ProjectPickerPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("toolbar contribution is available")
    func toolbarContribution() {
        #expect(!ProjectPickerPlugin.toolbarLeadingItems(context: GitOKPluginContext()).isEmpty)
    }
}
