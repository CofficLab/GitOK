import Foundation
import GitOKUI

class ThemeConflictPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeConflictPlugin()
    static var order: Int { 124 }
    static var displayName: String { "Conflict Theme" }
    static var description: String { "Focused merge conflict review theme" }
    static var iconName: String { "exclamationmark.triangle" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeConflictPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.conflict, order: Self.order)]
    }
}
