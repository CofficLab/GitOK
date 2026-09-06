import LumiUI
import SwiftUI

/// 设置页插件关于视图。
struct PluginSettingViewAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "sidebar.squares.leading.rectangle",
                accent: theme.primary,
                tagline: L("A home for every plugin's preferences."),
                chips: [L("Sidebar"), L("Sections"), L("Extensible")],
                metrics: [
                    .init(value: "1", label: L("settings window")),
                    .init(value: "N", label: L("sections"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "sidebar.squares.leading", tint: theme.primary,
                          title: L("Section Sidebar"),
                          description: L("All settings are organized in a navigable sidebar.")),
                    .init(icon: "puzzlepiece.extension", tint: theme.info,
                          title: L("Plugin Sections"),
                          description: L("Each plugin contributes its own settings page.")),
                    .init(icon: "magnifyingglass", tint: theme.warning,
                          title: L("Searchable"),
                          description: L("Jump to any setting by typing."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register"), description: L("Plugins register setting sections with titles."), icon: "plus.square"),
                    .init(title: L("Compose"), description: L("The settings window assembles the sidebar."), icon: "macwindow"),
                    .init(title: L("Navigate"), description: L("Selecting a section shows its content."), icon: "arrow.right.circle")
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
    ScrollView { PluginSettingViewAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
