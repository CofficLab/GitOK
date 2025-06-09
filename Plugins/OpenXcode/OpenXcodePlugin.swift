import MagicCore
import OSLog
import SwiftUI

class OpenXcodePlugin: SuperPlugin, SuperLog {
    static let shared = OpenXcodePlugin()
    let emoji = "🛠️"
    static var label: String = "OpenXcode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenXcodeView.shared)
    }
}
