import Foundation

public enum GitDetailImageDiffMode: String, CaseIterable, Identifiable {
    case twoUp
    case swipe
    case onion
    case difference

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .twoUp: return String(localized: "Side by Side")
        case .swipe: return String(localized: "Swipe")
        case .onion: return String(localized: "Overlay")
        case .difference: return String(localized: "Difference")
        }
    }

    public var usesBlendAmount: Bool {
        switch self {
        case .swipe, .onion:
            return true
        case .twoUp, .difference:
            return false
        }
    }

    public var sliderAccessibilityLabel: String {
        switch self {
        case .swipe:
            return String(localized: "Swipe divider position")
        case .onion:
            return String(localized: "Modified image opacity")
        case .twoUp, .difference:
            return ""
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .twoUp:
            return String(localized: "Image side-by-side comparison")
        case .swipe:
            return String(localized: "Image swipe comparison")
        case .onion:
            return String(localized: "Image overlay comparison")
        case .difference:
            return String(localized: "Image difference blend comparison")
        }
    }

    public var accessibilityHint: String {
        switch self {
        case .twoUp:
            return String(localized: "Shows the before and after images side by side")
        case .swipe:
            return String(localized: "Use the slider to adjust the position where the modified image overlays the original")
        case .onion:
            return String(localized: "Use the slider to adjust the opacity of the modified image overlaid on the original")
        case .difference:
            return String(localized: "Uses difference blend mode to highlight areas where the two images differ")
        }
    }

    public func valueLabel(for value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
