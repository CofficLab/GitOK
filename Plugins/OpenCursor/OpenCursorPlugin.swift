import SwiftUI
import MagicCore
import OSLog

class OpenCursorPlugin: SuperPlugin, SuperLog {
    let emoji = "🖱️"
    var label: String = "OpenCursor"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenCursorView())
    }
}
