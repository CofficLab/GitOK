import Foundation
import GitOKUI

class ThemeEmberPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeEmberPlugin()
    static var order: Int { 124 }
    static var displayName: String { "Ember Theme" }
    static var description: String { "Warm orange dark theme" }
    static var iconName: String { "exclamationmark.triangle" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeEmberPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.conflict, order: Self.order)]
    }
}
