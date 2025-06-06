import MagicCore
import OSLog
import SwiftUI

class SmartFilePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartFile"
    var isTab: Bool = false
    
    func addStatusBarLeadingView() -> AnyView {
        AnyView(TileFile())
    }
}
