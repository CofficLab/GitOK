import SwiftUI
import MagicCore
import OSLog

class OpenFinderPlugin: SuperPlugin, SuperLog {
    let emoji = "📂"
    var label: String = "OpenFinder"
    var icon: String = "folder"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenFinderView())
    }
}
