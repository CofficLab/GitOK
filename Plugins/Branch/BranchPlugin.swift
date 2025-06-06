import SwiftUI
import MagicCore
import OSLog

class BranchPlugin: SuperPlugin, SuperLog {
    let emoji = "🌿"
    static var label: String = "Branch"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BranchesView())
    }
}
