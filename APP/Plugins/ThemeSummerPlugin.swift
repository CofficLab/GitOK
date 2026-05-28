import Foundation
import GitOKUI

class ThemeSummerPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeSummerPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 130 }
    static var displayName: String { "Summer Theme" }
    static var description: String { "Warm golden light theme" }
    static var iconName: String { "tag" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeSummerPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.release, order: Self.order)]
    }
}
