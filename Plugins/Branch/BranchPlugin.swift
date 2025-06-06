import SwiftUI
import MagicCore
import OSLog

class BranchPlugin: SuperPlugin, SuperLog {
    let emoji = "🌿"
    static let shared = BranchPlugin()
    static var label: String = "Branch"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarLeadingView() -> AnyView {
        AnyView(BranchesView())
    }
}
