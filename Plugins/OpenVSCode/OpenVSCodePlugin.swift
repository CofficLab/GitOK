import SwiftUI
import MagicCore
import OSLog

class OpenVSCodePlugin: SuperPlugin, SuperLog {
    let emoji = "💻"
    static var label: String = "OpenVSCode"
    var isTab: Bool = false

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenVSCodeView())
    }
}
