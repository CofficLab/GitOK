import SwiftUI
import MagicCore
import OSLog

class OpenVSCodePlugin: SuperPlugin, SuperLog {
    let emoji = "💻"
    var label: String = "OpenVSCode"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenVSCodeView())
    }
}
