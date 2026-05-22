import Foundation
import GitOKUI

class ThemePullRequestPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemePullRequestPlugin()
    static var order: Int { 126 }
    static var displayName: String { "Pull Request Theme" }
    static var description: String { "Incoming changes review theme" }
    static var iconName: String { "arrow.triangle.pull" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemePullRequestPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.pullRequest, order: Self.order)]
    }
}
