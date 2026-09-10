import LumiUI
import SwiftUI

/// Rail 视图插件关于页面
struct RailViewAboutView: View {
    var body: some View {
        PluginOnboardingPageView(
            emoji: "📋",
            title: "Rail View",
            description: "The rail view provides a collapsible side panel that displays commit history and other contextual information for the current project.",
            features: [
                .init(icon: "clock", title: "Commit History", description: "View and navigate through the commit history of your current project"),
                .init(icon: "arrow.left.arrow.right", title: "Tab Navigation", description: "Switch between different rail tabs to access various features"),
                .init(icon: "arrow.left.and.right.text.vertical", title: "Resizable", description: "Drag the rail border to resize it to your preferred width"),
            ]
        )
    }
}
