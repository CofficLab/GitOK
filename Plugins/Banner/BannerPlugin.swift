import MagicCore
import OSLog
import SwiftUI

class BannerPlugin: SuperPlugin, SuperLog {
    static let shared = BannerPlugin()
    let emoji = "📣"
    static var label: String = "Banner"
    var isTab: Bool = true
    
    private init() {}

    func addDetailView() -> AnyView? {
        AnyView(BannerDetailLayout.shared.environmentObject(BannerProvider.shared))
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
