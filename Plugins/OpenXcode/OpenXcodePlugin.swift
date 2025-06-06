import SwiftUI
import MagicCore
import OSLog

class OpenXcodePlugin: SuperPlugin, SuperLog {
    let emoji = "🛠️"
    var label: String = "OpenXcode"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenXcodeView())
    }
}
