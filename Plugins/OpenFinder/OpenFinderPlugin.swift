import SwiftUI
import MagicCore
import OSLog

class OpenFinderPlugin: SuperPlugin, SuperLog {
    static let shared = OpenFinderPlugin()
    let emoji = "📂"
    static var label: String = "OpenFinder"
    var isTab: Bool = false
    
    private init() {}

    func addToolBarTrailingView() -> AnyView {
        AnyView(BtnOpenFinderView())
    }
}
