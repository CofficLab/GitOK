import Foundation
import GitOKUI

class ThemeMidnightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeMidnightPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 123 }
    static var displayName: String { "Midnight Theme" }
    static var description: String { "Quiet terminal-green dark theme" }
    static var iconName: String { "terminal" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeMidnightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.terminal, order: Self.order)]
    }
}
