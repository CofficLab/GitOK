import MagicCore
import OSLog
import SwiftUI

class RemoteRepositoryPlugin: SuperPlugin, SuperLog {
    static let shared = RemoteRepositoryPlugin()
    static let emoji = "🔗"
    static var label: String = "RemoteRepository"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(BtnRemoteRepositoryView.shared)
    }
} 
