import SwiftUI
import MagicCore
import OSLog

class OpenTraePlugin: SuperPlugin, SuperLog {
    let emoji = "🤖"
    var label: String = "OpenTrae"
    var icon: String = "brain.head.profile"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenTraeView())
    }
}
