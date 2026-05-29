import Foundation
import GitOKUI

class ThemeGraphitePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGraphitePlugin()
    @objc static let shouldRegister = false
    static var order: Int { 134 }
    static var displayName: String { "Graphite Theme" }
    static var description: String { "Neutral graphite dark theme" }
    static var iconName: String { "square.grid.3x3" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGraphitePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.graphite, order: Self.order)]
    }
}
