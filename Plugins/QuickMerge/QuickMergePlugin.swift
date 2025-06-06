import MagicCore
import OSLog
import SwiftUI

class QuickMergePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "QuickMerge"
    var isTab: Bool = false
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileQuickMerge())
    }
}
