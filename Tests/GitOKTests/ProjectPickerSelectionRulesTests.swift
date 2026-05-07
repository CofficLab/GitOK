import Foundation
import Testing

@Suite("ProjectPickerSelectionRulesTests")
struct ProjectPickerSelectionRulesTests {
    @Test("Selection change only applies when new project differs")
    func selectionChangeOnlyAppliesWhenNewProjectDiffers() {
        #expect(ProjectPickerSelectionRules.shouldApplySelectionChange(newSelection: "a", currentProject: "b"))
        #expect(!ProjectPickerSelectionRules.shouldApplySelectionChange(newSelection: "a", currentProject: "a"))
        #expect(!ProjectPickerSelectionRules.shouldApplySelectionChange(newSelection: nil as String?, currentProject: "a"))
    }

    @Test("Synced selection keeps current value unless project changed")
    func syncedSelectionKeepsCurrentValueUnlessProjectChanged() {
        #expect(ProjectPickerSelectionRules.syncedSelection(currentSelection: "a", currentProject: "a") == "a")
        #expect(ProjectPickerSelectionRules.syncedSelection(currentSelection: "a", currentProject: "b") == "b")
        #expect(ProjectPickerSelectionRules.syncedSelection(currentSelection: "a", currentProject: nil as String?) == "a")
    }
}
