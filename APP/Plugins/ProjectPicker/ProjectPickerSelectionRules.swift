import Foundation

enum ProjectPickerSelectionRules {
    static func shouldApplySelectionChange<Selection: Equatable>(
        newSelection: Selection?,
        currentProject: Selection?
    ) -> Bool {
        guard let newSelection else { return false }
        return newSelection != currentProject
    }

    static func syncedSelection<Selection: Equatable>(
        currentSelection: Selection?,
        currentProject: Selection?
    ) -> Selection? {
        guard let currentProject else { return currentSelection }
        return currentProject == currentSelection ? currentSelection : currentProject
    }
}
