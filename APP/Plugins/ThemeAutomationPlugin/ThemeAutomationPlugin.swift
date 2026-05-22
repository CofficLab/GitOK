import Foundation
import GitOKUI

class ThemeAutomationPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeAutomationPlugin()
    static var order: Int { 131 }
    static var displayName: String { "Automation Theme" }
    static var description: String { "Background Git task theme" }
    static var iconName: String { "gearshape.2" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeAutomationPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.automation, order: Self.order)]
    }
}
