import SwiftUI
import MagicCore
import OSLog

class BranchPlugin: SuperPlugin, SuperLog {
    let emoji = "🌿"
    var label: String = "Branch"
    var icon: String = "arrow.triangle.branch"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BranchesView())
    }
}
