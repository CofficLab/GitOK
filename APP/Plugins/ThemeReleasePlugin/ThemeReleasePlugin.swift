import Foundation
import GitOKUI

class ThemeReleasePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeReleasePlugin()
    static var order: Int { 130 }
    static var displayName: String { "Release Theme" }
    static var description: String { "Tags and release preparation theme" }
    static var iconName: String { "tag" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeReleasePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.release, order: Self.order)]
    }
}
