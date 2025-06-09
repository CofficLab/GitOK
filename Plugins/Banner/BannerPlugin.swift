import MagicCore
import OSLog
import SwiftUI

class BannerPlugin: SuperPlugin, SuperLog {
    static let shared = BannerPlugin()
    let emoji = "📣"
    static var label: String = "Banner"
    var isTab: Bool = true
    
    private init() {}

    func addListView(tab: String, project: Project?) -> AnyView? {
        if tab == Self.label {
            AnyView(BannerList())
        } else {
            nil
        }
    }

    func addDetailView() -> AnyView? {
        AnyView(BannerDetail())
    }
}
