import Foundation
import GitOKUI

class ThemeRepositoryPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeRepositoryPlugin()
    static var order: Int { 120 }
    static var displayName: String { "Repository Theme" }
    static var description: String { "Repository-focused dark theme" }
    static var iconName: String { "folder.badge.gearshape" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeRepositoryPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.repository, order: Self.order)]
    }
}
