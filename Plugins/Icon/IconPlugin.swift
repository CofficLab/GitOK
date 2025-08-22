import MagicCore
import OSLog
import SwiftUI

class IconPlugin: SuperPlugin, SuperLog {
    static let shared = IconPlugin()
    let emoji = "📣"
    static var label: String = "Icon"
    var isTab: Bool = true
    
    private init() {}

    func addListView(tab: String, project: Project?) -> AnyView? {
        if Self.label == tab {
            AnyView(IconList())
        } else {
            nil
        }
    }

    func addDetailView() -> AnyView? {
        AnyView(DetailIcon.shared)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab("Icon")
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .setInitialTab("Icon")
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
