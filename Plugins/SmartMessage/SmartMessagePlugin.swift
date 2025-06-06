import MagicCore
import OSLog
import SwiftUI

class SmartMessagePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartMessage"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMessage())
    }
}
