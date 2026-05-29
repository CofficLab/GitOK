import Foundation
import GitOKUI

class ThemeNebulaPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeNebulaPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 126 }
    static var displayName: String { "Nebula Theme" }
    static var description: String { "Violet atmospheric dark theme" }
    static var iconName: String { "arrow.triangle.pull" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeNebulaPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.pullRequest, order: Self.order)]
    }
}
