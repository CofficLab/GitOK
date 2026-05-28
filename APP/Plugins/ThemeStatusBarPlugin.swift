import Foundation
import SwiftUI

class ThemeStatusBarPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeStatusBarPlugin()
    @objc static let shouldRegister = false

    static var order: Int { 119 }
    static var displayName: String { "Theme Status" }
    static var description: String { "Switch themes from the status bar" }
    static var iconName: String { "paintbrush" }
    static var allowUserToggle: Bool { false }

    nonisolated var instanceLabel: String { "ThemeStatusBarPlugin" }

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ThemeStatusBarView())
    }
}
