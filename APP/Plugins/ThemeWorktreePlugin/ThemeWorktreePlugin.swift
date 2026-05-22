import Foundation
import GitOKUI

class ThemeWorktreePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeWorktreePlugin()
    static var order: Int { 121 }
    static var displayName: String { "Worktree Theme" }
    static var description: String { "Light worktree browsing theme" }
    static var iconName: String { "tree" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeWorktreePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.worktree, order: Self.order)]
    }
}
