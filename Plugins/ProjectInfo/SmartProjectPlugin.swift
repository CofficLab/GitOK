import MagicCore
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartProject"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarLeadingView() -> AnyView {
        AnyView(TileProject())
    }
}
