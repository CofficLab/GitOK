import Foundation
import GitOKUI

class ThemeAuroraPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeAuroraPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 122 }
    static var displayName: String { "Aurora Theme" }
    static var description: String { "Deep cyan night theme" }
    static var iconName: String { "point.3.connected.trianglepath.dotted" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeAuroraPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.commitGraph, order: Self.order)]
    }
}
