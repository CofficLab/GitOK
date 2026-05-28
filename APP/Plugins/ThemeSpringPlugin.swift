import Foundation
import GitOKUI

class ThemeSpringPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeSpringPlugin()
    @objc static let shouldRegister = false
    static var order: Int { 121 }
    static var displayName: String { "Spring Theme" }
    static var description: String { "Fresh green light theme" }
    static var iconName: String { "tree" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeSpringPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.worktree, order: Self.order)]
    }
}
