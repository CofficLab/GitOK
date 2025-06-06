import SwiftUI
import MagicCore
import OSLog

class OpenFinderPlugin: SuperPlugin, SuperLog {
    let emoji = "📂"
    static var label: String = "OpenFinder"
    var isTab: Bool = false

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenFinderView())
    }
}
