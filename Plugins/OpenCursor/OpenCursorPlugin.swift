import SwiftUI
import MagicCore
import OSLog

class OpenCursorPlugin: SuperPlugin, SuperLog {
    static let shared = OpenCursorPlugin()
    let emoji = "🖱️"
    static var label: String = "OpenCursor"

    
    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenCursorView.shared)
    }
}
