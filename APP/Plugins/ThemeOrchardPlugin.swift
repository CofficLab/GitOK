import Foundation
import GitOKUI

class ThemeOrchardPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeOrchardPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 128 }
    static var displayName: String { "Orchard Theme" }
    static var description: String { "Earthy amber dark theme" }
    static var iconName: String { "tray.full" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeOrchardPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.stash, order: Self.order)]
    }
}
