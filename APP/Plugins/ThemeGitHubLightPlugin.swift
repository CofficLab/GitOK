import Foundation
import GitOKUI

class ThemeGitHubLightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGitHubLightPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 138 }
    static var displayName: String { "GitHub Light Theme" }
    static var description: String { "GitHub-inspired light theme" }
    static var iconName: String { "globe" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGitHubLightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.githubLight, order: Self.order)]
    }
}
