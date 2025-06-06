import MagicCore
import OSLog
import SwiftUI

class OpenTerminalPlugin: SuperPlugin, SuperLog {
    let emoji = "⌨️"
    static var label: String = "OpenTerminal"
    var isTab: Bool = false

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenTerminalView())
    }
}
