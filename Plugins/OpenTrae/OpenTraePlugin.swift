import SwiftUI
import MagicCore
import OSLog

class OpenTraePlugin: SuperPlugin, SuperLog {
    static let shared = OpenTraePlugin()
    let emoji = "🤖"
    static var label: String = "OpenTrae"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenTraeView.shared)
    }
}
