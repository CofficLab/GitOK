import Foundation
import Testing

@Suite("BannerTemplateSelectionRulesTests")
struct BannerTemplateSelectionRulesTests {
    @Test("Keeps existing selection when one is already active")
    func keepsExistingSelectionWhenOneIsAlreadyActive() {
        #expect(
            BannerTemplateSelectionRules.initialSelectionID(
                currentSelectionID: "classic",
                lastSelectedTemplateID: "minimal",
                availableTemplateIDs: ["classic", "minimal"],
                defaultTemplateID: "classic"
            ) == nil
        )
    }

    @Test("Prefers last selected template when still available")
    func prefersLastSelectedTemplateWhenStillAvailable() {
        #expect(
            BannerTemplateSelectionRules.initialSelectionID(
                currentSelectionID: "",
                lastSelectedTemplateID: "minimal",
                availableTemplateIDs: ["classic", "minimal"],
                defaultTemplateID: "classic"
            ) == "minimal"
        )
    }

    @Test("Falls back to default then first available template")
    func fallsBackToDefaultThenFirstAvailableTemplate() {
        #expect(
            BannerTemplateSelectionRules.initialSelectionID(
                currentSelectionID: "",
                lastSelectedTemplateID: "missing",
                availableTemplateIDs: ["classic", "minimal"],
                defaultTemplateID: "classic"
            ) == "classic"
        )
        #expect(
            BannerTemplateSelectionRules.initialSelectionID(
                currentSelectionID: "",
                lastSelectedTemplateID: "",
                availableTemplateIDs: ["minimal"],
                defaultTemplateID: "classic"
            ) == "minimal"
        )
        #expect(
            BannerTemplateSelectionRules.initialSelectionID(
                currentSelectionID: "",
                lastSelectedTemplateID: "",
                availableTemplateIDs: [],
                defaultTemplateID: "classic"
            ) == nil
        )
    }
}
