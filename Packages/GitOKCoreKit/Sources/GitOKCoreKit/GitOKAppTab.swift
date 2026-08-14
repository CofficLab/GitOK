import Foundation

/// Main window workspace tab identifiers owned by the app shell.
public enum GitOKAppTab: String, CaseIterable, Sendable, Codable, Identifiable {
    case git

    public var id: String { rawValue }

    /// Resolves a persisted tab value from legacy display names or raw values.
    ///
    /// Legacy values from removed tabs (`banner`, `icon`) fall back to `nil`,
    /// letting callers default to the git workspace.
    public static func migrated(from stored: String) -> GitOKAppTab? {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let tab = GitOKAppTab(rawValue: trimmed) {
            return tab
        }

        switch trimmed {
        case "Git":
            return .git
        default:
            return nil
        }
    }
}
