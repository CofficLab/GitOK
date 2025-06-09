import MagicCore
import OSLog
import SwiftUI

class OpenTraePlugin: SuperPlugin, SuperLog {
    static let shared = OpenTraePlugin()
    let emoji = "🤖"
    static var label: String = "OpenTrae"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenTraeView.shared)
    }
}
