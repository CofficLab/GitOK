import Foundation
import GitOKUI

class ThemeWinterPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeWinterPlugin()
    static var order: Int { 133 }
    static var displayName: String { "Winter Theme" }
    static var description: String { "Cool minimal light theme" }
    static var iconName: String { "scope" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeWinterPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.focus, order: Self.order)]
    }
}
