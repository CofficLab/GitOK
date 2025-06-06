import MagicCore
import OSLog
import SwiftUI

class SmartMessagePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartMessage"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMessage())
    }
}
