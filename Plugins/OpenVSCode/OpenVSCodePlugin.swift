import SwiftUI
import MagicCore
import OSLog

class OpenVSCodePlugin: SuperPlugin, SuperLog {
    static let shared = OpenVSCodePlugin()
    let emoji = "💻"
    static var label: String = "OpenVSCode"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenVSCodeView.shared)
    }
}
