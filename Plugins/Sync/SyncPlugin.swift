import SwiftUI
import MagicCore
import OSLog

class SyncPlugin: SuperPlugin, SuperLog {
    let emoji = "🔄"
    var label: String = "Sync"
    var icon: String = "arrow.triangle.2.circlepath"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnSyncView())
    }
}
