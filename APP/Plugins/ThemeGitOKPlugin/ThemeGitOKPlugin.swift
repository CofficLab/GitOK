import Foundation
import GitOKUI

class ThemeGitOKPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGitOKPlugin()
    static var order: Int { 120 }
    static var displayName: String { "GitOK Theme" }
    static var description: String { "Default GitOK dark theme" }
    static var iconName: String { "folder.badge.gearshape" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGitOKPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.repository, order: Self.order)]
    }
}
