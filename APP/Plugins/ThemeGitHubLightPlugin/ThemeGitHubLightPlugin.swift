import Foundation
import GitOKUI

class ThemeGitHubLightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGitHubLightPlugin()
    static var order: Int { 138 }
    static var displayName: String { "GitHub Light Theme" }
    static var description: String { "GitHub-like light review theme" }
    static var iconName: String { "globe" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGitHubLightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.githubLight, order: Self.order)]
    }
}
