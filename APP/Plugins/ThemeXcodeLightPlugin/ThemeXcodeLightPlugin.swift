import Foundation
import GitOKUI

class ThemeXcodeLightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeXcodeLightPlugin()
    static var order: Int { 137 }
    static var displayName: String { "Xcode Light Theme" }
    static var description: String { "Xcode-inspired light theme" }
    static var iconName: String { "hammer" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeXcodeLightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.xcodeLight, order: Self.order)]
    }
}
