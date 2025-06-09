import MagicCore
import OSLog
import SwiftUI

class SyncPlugin: SuperPlugin, SuperLog {
    static let shared = SyncPlugin()
    let emoji = "🔄"
    static var label: String = "Sync"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnSyncView.shared)
    }
}
