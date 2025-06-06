import MagicCore
import OSLog
import SwiftUI

class SmartFilePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartFile"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarLeadingView() -> AnyView {
        AnyView(TileFile())
    }
}
