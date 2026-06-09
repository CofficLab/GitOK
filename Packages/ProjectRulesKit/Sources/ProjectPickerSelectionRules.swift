import Foundation

public enum ProjectPickerSelectionRules {
    public static func shouldApplySelectionChange<Selection: Equatable>(
        newSelection: Selection?,
        currentProject: Selection?
    ) -> Bool {
        guard let newSelection else { return false }
        return newSelection != currentProject
    }

    public static func syncedSelection<Selection: Equatable>(
        currentSelection: Selection?,
        currentProject: Selection?
    ) -> Selection? {
        guard let currentProject else { return currentSelection }
        return currentProject == currentSelection ? currentSelection : currentProject
    }
}
