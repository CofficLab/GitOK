import LumiUI
import SwiftUI

/// 项目列表插件关于视图。
struct ProjectsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "folder",
                accent: theme.primary,
                tagline: L("Your repositories, always one click away."),
                chips: [L("Recent"), L("Pinned"), L("Quick Open")],
                metrics: [
                    .init(value: "1", label: L("click to open")),
                    .init(value: "∞", label: L("projects"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "clock.arrow.circlepath", tint: theme.primary,
                          title: L("Recents"),
                          description: L("Recently opened projects surface at the top, newest first.")),
                    .init(icon: "pin.fill", tint: theme.warning,
                          title: L("Pinned Projects"),
                          description: L("Pin frequently used repositories so they never leave your sight.")),
                    .init(icon: "magnifyingglass", tint: theme.info,
                          title: L("Search & Filter"),
                          description: L("Type to filter the whole list by name, path, or platform."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Record opens"), description: L("Every project you open is remembered in order."), icon: "clock"),
                    .init(title: L("Build the list"), description: L("Recents, pins, and search results merge into one list."), icon: "list.bullet"),
                    .init(title: L("Open in place"), description: L("Clicking a project switches the whole workspace to it."), icon: "arrow.right.circle")
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
    ScrollView { ProjectsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
