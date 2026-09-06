import LumiUI
import SwiftUI

/// 根视图插件关于视图。
struct RootViewAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "macwindow",
                accent: theme.primary,
                tagline: L("The window that hosts the entire GitOK workspace."),
                chips: [L("Sidebar"), L("Content"), L("Status Bar")],
                metrics: [
                    .init(value: "3", label: L("core regions")),
                    .init(value: "1", label: L("window"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "sidebar.left", tint: theme.primary,
                          title: L("Sidebar"),
                          description: L("Project list, repository tree, and navigation live on the left.")),
                    .init(icon: "rectangle.inset.filled.and.person.filled", tint: theme.info,
                          title: L("Content Area"),
                          description: L("Commits, diffs, worktrees, and settings render in the main pane.")),
                    .init(icon: "rectangle.bottomthird.inset.filled", tint: theme.warning,
                          title: L("Status Bar"),
                          description: L("Branch, worktree, and activity indicators sit at the bottom."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register regions"), description: L("Each feature registers its toolbar, sidebar, or content views."), icon: "square.on.square"),
                    .init(title: L("Compose the window"), description: L("The root view assembles all registered regions into one layout."), icon: "macwindow"),
                    .init(title: L("Switch projects"), description: L("Opening a project re-renders the workspace around it."), icon: "arrow.triangle.2.circlepath")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        LumiPluginLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { RootViewAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
