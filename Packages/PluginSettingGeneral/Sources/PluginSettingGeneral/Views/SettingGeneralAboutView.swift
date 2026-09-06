import LumiUI
import SwiftUI

/// 通用设置插件关于视图。
struct SettingGeneralAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "switch.2",
                accent: theme.info,
                tagline: L("The app-wide preferences that tie everything together."),
                chips: [L("General"), L("App Info"), L("Behavior")],
                metrics: [
                    .init(value: "1", label: L("general page")),
                    .init(value: "∞", label: L("options"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "slider.horizontal.3", tint: theme.info,
                          title: L("General Options"),
                          description: L("Launch behavior, window, and interface preferences.")),
                    .init(icon: "info.circle", tint: theme.primary,
                          title: L("App Information"),
                          description: L("Version, build, and environment details at a glance.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.success,
                          title: L("Instant Apply"),
                          description: L("Changes apply immediately, no restarts required."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Open General"), description: L("The general section opens in settings."), icon: "gearshape"),
                    .init(title: L("Adjust"), description: L("Toggle app-wide behaviors."), icon: "switch.2"),
                    .init(title: L("Apply"), description: L("Preferences persist and take effect at once."), icon: "checkmark.circle")
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
    ScrollView { SettingGeneralAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
