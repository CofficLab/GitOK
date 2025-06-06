import SwiftUI
import MagicCore
import OSLog

class SyncPlugin: SuperPlugin, SuperLog {
    let emoji = "🔄"
    var label: String = "Sync"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnSyncView())
    }
}
