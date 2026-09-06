import LumiUI
import SwiftUI

/// 图标导出插件关于视图。
struct IconAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "app.badge.fill",
                accent: theme.primary,
                tagline: L("App icons, sized for every platform automatically."),
                chips: [L("All sizes"), L("Export"), L("Branded")],
                metrics: [
                    .init(value: "1", label: L("source icon")),
                    .init(value: "N", label: L("output sizes"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "app", tint: theme.primary,
                          title: L("Icon Generation"),
                          description: L("Compose app icons from GitOK's visual language.")),
                    .init(icon: "square.grid.3x3", tint: theme.info,
                          title: L("Multi-Size Export"),
                          description: L("Every required icon size is rendered in one pass.")),
                    .init(icon: "paintpalette", tint: theme.warning,
                          title: L("Theme Aware"),
                          description: L("Colors and styles follow the active theme."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Design"), description: L("Pick the icon style and colors."), icon: "paintpalette"),
                    .init(title: L("Render sizes"), description: L("All required resolutions are rendered."), icon: "square.grid.3x3"),
                    .init(title: L("Export"), description: L("Icons are written to the destination folder."), icon: "arrow.down.doc")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        IconLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { IconAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
