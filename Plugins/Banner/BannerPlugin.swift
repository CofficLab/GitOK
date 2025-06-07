import MagicCore
import OSLog
import SwiftUI

class BannerPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "Banner"
    var isTab: Bool = true

    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == Self.label {
            AnyView(BannerList())
        } else {
            nil
        }
    }

    func addDetailView() -> AnyView {
        AnyView(BannerDetail())
    }
}
