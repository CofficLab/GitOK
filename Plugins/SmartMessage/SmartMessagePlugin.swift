import MagicCore
import OSLog
import SwiftUI

class SmartMessagePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    static var label: String = "SmartMessage"
    var isTab: Bool = false
    static let shared = SmartMessagePlugin()
    
    private init() {}
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileMessage.shared)
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

