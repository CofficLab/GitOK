import Foundation
import GitOKUI

class ThemeHarborPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeHarborPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 127 }
    static var displayName: String { "Harbor Theme" }
    static var description: String { "Deep blue water theme" }
    static var iconName: String { "network" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeHarborPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.remote, order: Self.order)]
    }
}
