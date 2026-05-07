import Foundation

enum BannerTemplateSelectionRules {
    static func initialSelectionID(
        currentSelectionID: String,
        lastSelectedTemplateID: String,
        availableTemplateIDs: [String],
        defaultTemplateID: String
    ) -> String? {
        if !currentSelectionID.isEmpty {
            return nil
        }

        if !lastSelectedTemplateID.isEmpty,
           availableTemplateIDs.contains(lastSelectedTemplateID) {
            return lastSelectedTemplateID
        }

        guard availableTemplateIDs.contains(defaultTemplateID) else {
            return availableTemplateIDs.first
        }

        return defaultTemplateID
    }
}
