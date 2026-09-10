import LumiUI
import SwiftUI

/// 插件关于页面。
struct ProjectMissingAboutView: View {
    var body: some View {
        PluginOnboardingPageView(
            icon: "folder.badge.questionmark",
            displayName: "Project Missing",
            description: "Shows a friendly notice when the current project directory no longer exists on disk.",
            features: [
                .init(icon: "folder.badge.questionmark", title: "Missing Detection", description: "Automatically detects when the project directory has been deleted or moved."),
                .init(icon: "trash", title: "Quick Remove", description: "Provides a one-click action to remove the missing project from the project list."),
            ]
        )
    }
}
