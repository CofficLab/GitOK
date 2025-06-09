import MagicCore
import OSLog
import SwiftUI

class OpenFinderPlugin: SuperPlugin, SuperLog {
    static let shared = OpenFinderPlugin()
    let emoji = "📂"
    static var label: String = "OpenFinder"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenFinderView.shared)
    }
}
