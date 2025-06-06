import MagicCore
import OSLog
import SwiftUI

class OpenTerminalPlugin: SuperPlugin, SuperLog {
    let emoji = "⌨️"
    var label: String = "OpenTerminal"
    var icon: String = "apple.terminal"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenTerminalView())
    }
}
