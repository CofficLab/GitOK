import Foundation

/// Main window workspace tab identifiers owned by the app shell.
public enum GitOKAppTab: String, CaseIterable, Sendable, Codable, Identifiable {
    case git
    case banner
    case icon

    public var id: String { rawValue }

    /// Resolves a persisted tab value from legacy display names or raw values.
    public static func migrated(from stored: String) -> GitOKAppTab? {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let tab = GitOKAppTab(rawValue: trimmed) {
            return tab
        }

        switch trimmed {
        case "Git":
            return .git
        case "Banner":
            return .banner
        case "Icon":
            return .icon
        default:
            return nil
        }
    }
}
