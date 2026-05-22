import Foundation
import GitOKUI

class ThemeRemotePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeRemotePlugin()
    static var order: Int { 127 }
    static var displayName: String { "Remote Theme" }
    static var description: String { "Remote repository operations theme" }
    static var iconName: String { "network" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeRemotePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.remote, order: Self.order)]
    }
}
