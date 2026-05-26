import Foundation
import GitOKUI

class ThemeMountainPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeMountainPlugin()
    static var order: Int { 132 }
    static var displayName: String { "Mountain Theme" }
    static var description: String { "Quiet stone light theme" }
    static var iconName: String { "archivebox" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeMountainPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.archive, order: Self.order)]
    }
}
