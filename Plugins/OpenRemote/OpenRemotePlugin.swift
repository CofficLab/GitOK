import SwiftUI
import MagicCore
import OSLog

class OpenRemotePlugin: SuperPlugin, SuperLog {
    let emoji = "🌐"
    var label: String = "OpenRemote"
    var icon: String = "safari"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenRemoteView())
    }
}
