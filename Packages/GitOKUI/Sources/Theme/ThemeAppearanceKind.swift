import Foundation

/// Theme appearance category: fixed dark, fixed light, or following the system appearance.
public enum ThemeAppearanceKind: String, CaseIterable, Sendable, Identifiable {
    case dark
    case light
    case system

    public var id: String { rawValue }
}
