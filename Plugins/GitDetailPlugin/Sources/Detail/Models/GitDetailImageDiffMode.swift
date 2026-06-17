import GitOKCoreKit
import Foundation

public enum GitDetailImageDiffMode: String, CaseIterable, Identifiable {
    case twoUp
    case swipe
    case onion
    case difference

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .twoUp: return GitDetailLocalization.string("Side by Side")
        case .swipe: return GitDetailLocalization.string("Swipe")
        case .onion: return GitDetailLocalization.string("Overlay")
        case .difference: return GitDetailLocalization.string("Difference")
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
            return GitDetailLocalization.string("Swipe divider position")
        case .onion:
            return GitDetailLocalization.string("Modified image opacity")
        case .twoUp, .difference:
            return ""
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .twoUp:
            return GitDetailLocalization.string("Image side-by-side comparison")
        case .swipe:
            return GitDetailLocalization.string("Image swipe comparison")
        case .onion:
            return GitDetailLocalization.string("Image overlay comparison")
        case .difference:
            return GitDetailLocalization.string("Image difference blend comparison")
        }
    }

    public var accessibilityHint: String {
        switch self {
        case .twoUp:
            return GitDetailLocalization.string("Shows the before and after images side by side")
        case .swipe:
            return GitDetailLocalization.string("Use the slider to adjust the position where the modified image overlays the original")
        case .onion:
            return GitDetailLocalization.string("Use the slider to adjust the opacity of the modified image overlaid on the original")
        case .difference:
            return GitDetailLocalization.string("Uses difference blend mode to highlight areas where the two images differ")
        }
    }

    public func valueLabel(for value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
