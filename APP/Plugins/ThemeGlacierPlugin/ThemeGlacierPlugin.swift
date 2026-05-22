import Foundation
import GitOKUI

class ThemeGlacierPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGlacierPlugin()
    static var order: Int { 129 }
    static var displayName: String { "Glacier Theme" }
    static var description: String { "Icy cyan light theme" }
    static var iconName: String { "externaldrive" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGlacierPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.lfs, order: Self.order)]
    }
}
