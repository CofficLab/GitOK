import MagicCore
import OSLog
import SwiftUI

class BannerPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Banner"
    var icon: String = "camera"
    var isTab: Bool = true

    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == self.label {
            AnyView(BannerList())
        } else {
            nil
        }
    }

    func addDetailView() -> AnyView {
        AnyView(BannerDetail())
    }
}
