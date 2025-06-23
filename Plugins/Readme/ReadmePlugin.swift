import MagicCore
import OSLog
import SwiftUI

class ReadmePlugin: SuperPlugin, SuperLog {
    static let shared = ReadmePlugin()
    let emoji = "📖"
    static var label: String = "Readme"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ReadmeStatusIcon.shared)
    }
} 