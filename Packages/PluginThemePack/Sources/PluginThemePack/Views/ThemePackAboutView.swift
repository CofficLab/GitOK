import LumiUI
import SwiftUI

/// 主题包插件关于视图。
struct ThemePackAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "paintpalette.fill",
                accent: theme.primary,
                tagline: L("A look that feels like yours."),
                chips: [L("Themes"), L("Light/Dark"), L("Accent")],
                metrics: [
                    .init(value: "N", label: L("themes")),
                    .init(value: "1", label: L("click to switch"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "paintpalette", tint: theme.primary,
                          title: L("Theme Library"),
                          description: L("Switch between built-in light and dark themes.")),
                    .init(icon: "paintbrush.pointed.fill", tint: theme.info,
                          title: L("Accent Colors"),
                          description: L("Personalize the accent used across the UI.")),
                    .init(icon: "circle.lefthalf.filled", tint: theme.warning,
                          title: L("System Sync"),
                          description: L("Follow the system appearance automatically."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Pick a theme"), description: L("Choose from the theme library."), icon: "paintpalette"),
                    .init(title: L("Apply"), description: L("The theme is broadcast to the whole app."), icon: "wand.and.stars"),
                    .init(title: L("Persist"), description: L("Your choice is remembered across launches."), icon: "memorychip")
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
    ScrollView { ThemePackAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
