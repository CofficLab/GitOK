import Foundation
import GitOKUI

class ThemeStashPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeStashPlugin()
    static var order: Int { 128 }
    static var displayName: String { "Stash Theme" }
    static var description: String { "Temporary work theme" }
    static var iconName: String { "tray.full" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeStashPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.stash, order: Self.order)]
    }
}
