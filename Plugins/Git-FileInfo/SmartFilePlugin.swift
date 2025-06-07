import MagicCore
import OSLog
import SwiftUI

class SmartFilePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartFile"
    var isTab: Bool = false
    static let shared = SmartFilePlugin()
    
    private init() {}
    
    func addStatusBarLeadingView() -> AnyView {
        AnyView(TileFile())
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
