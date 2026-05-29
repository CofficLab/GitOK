import Foundation
import GitOKUI

class ThemeRiverPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeRiverPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 125 }
    static var displayName: String { "River Theme" }
    static var description: String { "Flowing teal dark theme" }
    static var iconName: String { "arrow.triangle.branch" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeRiverPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.branchFlow, order: Self.order)]
    }
}
