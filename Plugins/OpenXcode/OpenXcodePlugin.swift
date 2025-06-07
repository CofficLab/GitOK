import SwiftUI
import MagicCore
import OSLog

class OpenXcodePlugin: SuperPlugin, SuperLog {
    static let shared = OpenXcodePlugin()
    let emoji = "🛠️"
    static var label: String = "OpenXcode"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenXcodeView())
    }
}
