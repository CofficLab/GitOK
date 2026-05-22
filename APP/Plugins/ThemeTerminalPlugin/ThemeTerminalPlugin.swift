import Foundation
import GitOKUI

class ThemeTerminalPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeTerminalPlugin()
    static var order: Int { 123 }
    static var displayName: String { "Terminal Theme" }
    static var description: String { "Command-line oriented dark theme" }
    static var iconName: String { "terminal" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeTerminalPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.terminal, order: Self.order)]
    }
}
