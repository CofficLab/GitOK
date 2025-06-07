import SwiftUI
import MagicCore
import OSLog

class OpenRemotePlugin: SuperPlugin, SuperLog {
    static let shared = OpenRemotePlugin()
    static let emoji = "🌐"
    static var label: String = "OpenRemote"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenRemoteView())
    }
}
