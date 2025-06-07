import SwiftUI
import MagicCore
import OSLog

class OpenTraePlugin: SuperPlugin, SuperLog {
    let emoji = "🤖"
    static var label: String = "OpenTrae"
    var isTab: Bool = false

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenTraeView())
    }
}
