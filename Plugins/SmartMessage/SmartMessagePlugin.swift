import MagicCore
import OSLog
import SwiftUI

class SmartMessagePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartMessage"
    var isTab: Bool = false
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMessage())
    }
}
