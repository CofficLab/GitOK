import MagicCore
import OSLog
import SwiftUI

class BranchPlugin: SuperPlugin, SuperLog {
    let emoji = "🌿"
    static let shared = BranchPlugin()
    static var label: String = "Branch"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BranchesView.shared)
    }
}
