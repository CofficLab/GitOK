import Foundation

enum BannerTemplateCatalog {
    static let defaultTemplateID = "classic"
    static let defaultTemplateIDs = ["classic", "minimal"]

    static func registerTemplateID(_ id: String, into orderedIDs: inout [String]) {
        guard !orderedIDs.contains(id) else { return }
        orderedIDs.append(id)
    }

    static func containsTemplateID(_ id: String, in orderedIDs: [String]) -> Bool {
        orderedIDs.contains(id)
    }
}
