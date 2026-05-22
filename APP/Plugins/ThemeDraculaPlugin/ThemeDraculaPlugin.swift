import Foundation
import GitOKUI

class ThemeDraculaPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeDraculaPlugin()
    static var order: Int { 135 }
    static var displayName: String { "Dracula Theme" }
    static var description: String { "Classic vivid dark theme" }
    static var iconName: String { "moon.stars" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeDraculaPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.dracula, order: Self.order)]
    }
}
