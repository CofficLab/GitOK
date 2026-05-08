import Foundation

public enum BannerTemplateCatalog {
    public static let defaultTemplateID = "classic"
    public static let defaultTemplateIDs = ["classic", "minimal"]

    public static func registerTemplateID(_ id: String, into orderedIDs: inout [String]) {
        guard !orderedIDs.contains(id) else { return }
        orderedIDs.append(id)
    }

    public static func containsTemplateID(_ id: String, in orderedIDs: [String]) -> Bool {
        orderedIDs.contains(id)
    }
}
