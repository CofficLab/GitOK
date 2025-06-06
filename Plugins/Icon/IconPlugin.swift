import MagicCore
import OSLog
import SwiftUI

class IconPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Icon"
    var icon: String = "globe.europe.africa"
    var isTab: Bool = true

    func addListView(tab: String, project: Project?) -> AnyView? {
        if self.label == tab {
            AnyView(IconList())
        } else {
            nil
        }
    }

    func addDetailView() -> AnyView {
        AnyView(DetailIcon())
    }
}
