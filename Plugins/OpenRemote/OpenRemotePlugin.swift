import MagicCore
import OSLog
import SwiftUI

class OpenRemotePlugin: SuperPlugin, SuperLog {
    static let shared = OpenRemotePlugin()
    static let emoji = "🌐"
    static var label: String = "OpenRemote"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenRemoteView.shared)
    }
}
