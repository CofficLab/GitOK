import MagicCore
import OSLog
import SwiftUI

class SmartMergePlugin: SuperPlugin, SuperLog {
    static let shared = SmartMergePlugin()
    let emoji = "📣"
    static var label: String = "SmartMerge"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(TileMerge.shared)
    }
}
