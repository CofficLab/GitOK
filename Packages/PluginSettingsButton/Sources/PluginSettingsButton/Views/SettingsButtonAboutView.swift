import LumiUI
import SwiftUI

/// 设置按钮插件关于视图。
struct SettingsButtonAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "gearshape.fill",
                accent: theme.info,
                tagline: L("Every setting, one gear away."),
                chips: [L("Toolbar"), L("Settings"), L("Always there")],
                metrics: [
                    .init(value: "1", label: L("click")),
                    .init(value: "1", label: L("gear"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "gearshape", tint: theme.info,
                          title: L("Toolbar Entry"),
                          description: L("A gear button sits in the toolbar of the workspace.")),
                    .init(icon: "square.stack.3d.up", tint: theme.primary,
                          title: L("Settings Hub"),
                          description: L("Opens the settings window with all plugin sections.")),
                    .init(icon: "cursorarrow.click.2", tint: theme.warning,
                          title: L("Discoverability"),
                          description: L("Every preference is reachable without hunting."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Click the gear"), description: L("The toolbar button activates."), icon: "gearshape"),
                    .init(title: L("Open settings"), description: L("The settings window appears."), icon: "macwindow"),
                    .init(title: L("Browse sections"), description: L("All plugin settings are organized on the left."), icon: "list.bullet")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        SettingsButtonLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { SettingsButtonAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
