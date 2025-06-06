import MagicCore
import OSLog
import SwiftUI

class SmartMergePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartMerge"
    var isTab: Bool = false
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMerge())
    }
}
