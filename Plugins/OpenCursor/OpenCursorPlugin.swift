import SwiftUI
import MagicCore
import OSLog

class OpenCursorPlugin: SuperPlugin, SuperLog {
    let emoji = "🖱️"
    static var label: String = "OpenCursor"
    var isTab: Bool = false

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenCursorView())
    }
}
