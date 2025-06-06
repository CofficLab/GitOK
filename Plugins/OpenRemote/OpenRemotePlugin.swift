import SwiftUI
import MagicCore
import OSLog

class OpenRemotePlugin: SuperPlugin, SuperLog {
    static let emoji = "🌐"
    static var label: String = "OpenRemote"
    var isTab: Bool = false

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenRemoteView())
    }
}
