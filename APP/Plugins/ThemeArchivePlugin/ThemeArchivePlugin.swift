import Foundation
import GitOKUI

class ThemeArchivePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeArchivePlugin()
    static var order: Int { 132 }
    static var displayName: String { "Archive Theme" }
    static var description: String { "Repository cleanup and archive theme" }
    static var iconName: String { "archivebox" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeArchivePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.archive, order: Self.order)]
    }
}
