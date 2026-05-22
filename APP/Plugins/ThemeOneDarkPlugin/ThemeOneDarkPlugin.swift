import Foundation
import GitOKUI

class ThemeOneDarkPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeOneDarkPlugin()
    static var order: Int { 136 }
    static var displayName: String { "One Dark Theme" }
    static var description: String { "Classic editor dark theme" }
    static var iconName: String { "chevron.left.forwardslash.chevron.right" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeOneDarkPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.oneDark, order: Self.order)]
    }
}
