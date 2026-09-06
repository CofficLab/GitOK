import LumiUI
import SwiftUI

/// 侧边栏开关插件关于视图。
struct SidebarToggleAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "sidebar.left",
                accent: theme.primary,
                tagline: L("More room for code, whenever you need it."),
                chips: [L("Toggle"), L("Shortcut"), L("Instant")],
                metrics: [
                    .init(value: "1", label: L("shortcut")),
                    .init(value: "1", label: L("click"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "sidebar.left", tint: theme.primary,
                          title: L("Show / Hide"),
                          description: L("Collapse or expand the sidebar in one action.")),
                    .init(icon: "keyboard", tint: theme.info,
                          title: L("Keyboard Friendly"),
                          description: L("A shortcut keeps your hands on the keys.")),
                    .init(icon: "arrow.left.and.right", tint: theme.warning,
                          title: L("Workspace Focus"),
                          description: L("Free up horizontal space for content and diffs."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Trigger"), description: L("Click the toolbar button or press the shortcut."), icon: "sidebar.left"),
                    .init(title: L("Animate"), description: L("The sidebar collapses or expands smoothly."), icon: "arrow.left.and.right"),
                    .init(title: L("Persist"), description: L("Your preference is remembered for next time."), icon: "memorychip")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        SidebarToggleLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { SidebarToggleAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
