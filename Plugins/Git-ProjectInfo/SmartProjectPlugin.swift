import MagicCore
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartProject"

    
    func addStatusBarLeadingView() -> AnyView? {
        AnyView(TileProject.shared)
    }
}
