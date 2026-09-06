import LumiUI
import SwiftUI

/// 横幅导出插件关于视图。
struct BannerAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "rectangle.on.rectangle.angled",
                accent: theme.warning,
                tagline: L("Beautiful banner art, generated and exported in one step."),
                chips: [L("Export"), L("Assets"), L("Branded")],
                metrics: [
                    .init(value: "1", label: L("click to export")),
                    .init(value: "HD", label: L("resolution"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "photo.artframe", tint: theme.warning,
                          title: L("Banner Generation"),
                          description: L("Compose branded banners from GitOK's visual language.")),
                    .init(icon: "arrow.down.doc", tint: theme.info,
                          title: L("One-Click Export"),
                          description: L("Renders the banner to a file for social or marketing use.")),
                    .init(icon: "paintpalette", tint: theme.primary,
                          title: L("Theme Aware"),
                          description: L("Colors follow the active theme automatically."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Configure"), description: L("Choose text, style, and theme for the banner."), icon: "slider.horizontal.3"),
                    .init(title: L("Render"), description: L("The banner is drawn with the configured visuals."), icon: "photo.artframe"),
                    .init(title: L("Export"), description: L("The image is written to the destination you choose."), icon: "arrow.down.doc")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        BannerLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { BannerAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
