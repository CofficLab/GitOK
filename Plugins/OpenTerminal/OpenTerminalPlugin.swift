import MagicCore
import OSLog
import SwiftUI

class OpenTerminalPlugin: SuperPlugin, SuperLog {
    static let shared = OpenTerminalPlugin()
    let emoji = "⌨️"
    static var label: String = "OpenTerminal"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenTerminalView())
    }
}
