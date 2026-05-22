import Foundation
import GitOKUI

class ThemeCommitGraphPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeCommitGraphPlugin()
    static var order: Int { 122 }
    static var displayName: String { "Commit Graph Theme" }
    static var description: String { "Theme for reviewing commit history" }
    static var iconName: String { "point.3.connected.trianglepath.dotted" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeCommitGraphPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.commitGraph, order: Self.order)]
    }
}
