import Foundation
import GitOKUI

class ThemeLargeFilesPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeLargeFilesPlugin()
    static var order: Int { 129 }
    static var displayName: String { "Large Files Theme" }
    static var description: String { "Git LFS and binary asset theme" }
    static var iconName: String { "externaldrive" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeLargeFilesPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.lfs, order: Self.order)]
    }
}
