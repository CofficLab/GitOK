import Foundation
import GitOKUI

class ThemeBranchFlowPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeBranchFlowPlugin()
    static var order: Int { 125 }
    static var displayName: String { "Branch Flow Theme" }
    static var description: String { "Branch management theme" }
    static var iconName: String { "arrow.triangle.branch" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeBranchFlowPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.branchFlow, order: Self.order)]
    }
}
