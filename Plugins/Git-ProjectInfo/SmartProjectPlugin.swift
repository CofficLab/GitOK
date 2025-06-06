import MagicCore
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartProject"
    var isTab: Bool = false
    
    func addStatusBarLeadingView() -> AnyView {
        AnyView(TileProject())
    }
}
