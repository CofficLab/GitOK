import MagicCore
import OSLog
import SwiftUI

class QuickMergePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "QuickMerge"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileQuickMerge())
    }
}
