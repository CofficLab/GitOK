import MagicCore
import OSLog
import SwiftUI

class SmartMergePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartMerge"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMerge())
    }
}
