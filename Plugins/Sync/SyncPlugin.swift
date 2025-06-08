import SwiftUI
import MagicCore
import OSLog

class SyncPlugin: SuperPlugin, SuperLog {
    static let shared = SyncPlugin()
    let emoji = "🔄"
    static var label: String = "Sync"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnSyncView.shared)
    }
}
