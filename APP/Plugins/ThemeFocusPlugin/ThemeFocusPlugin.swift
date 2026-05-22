import Foundation
import GitOKUI

class ThemeFocusPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeFocusPlugin()
    static var order: Int { 133 }
    static var displayName: String { "Focus Theme" }
    static var description: String { "Minimal status review theme" }
    static var iconName: String { "scope" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeFocusPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.focus, order: Self.order)]
    }
}
