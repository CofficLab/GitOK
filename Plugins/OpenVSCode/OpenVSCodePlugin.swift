import MagicCore
import OSLog
import SwiftUI

class OpenVSCodePlugin: SuperPlugin, SuperLog {
    static let shared = OpenVSCodePlugin()
    let emoji = "💻"
    static var label: String = "OpenVSCode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenVSCodeView.shared)
    }
}
