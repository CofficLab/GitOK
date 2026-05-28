import Foundation
import GitOKUI

class ThemeMatrixPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeMatrixPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 131 }
    static var displayName: String { "Matrix Theme" }
    static var description: String { "Electric green dark theme" }
    static var iconName: String { "gearshape.2" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeMatrixPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.automation, order: Self.order)]
    }
}
