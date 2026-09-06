import LumiUI
import SwiftUI

/// Coffic Logo 插件关于视图。
struct LogoCofficAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "logo.bitbucket",
                accent: theme.primary,
                tagline: L("The Coffic mark that fronts GitOK."),
                chips: [L("Brand"), L("Coffic"), L("Always on")],
                metrics: [
                    .init(value: "1", label: L("logo")),
                    .init(value: "1", label: L("owner"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "logo.bitbucket", tint: theme.primary,
                          title: L("Brand Mark"),
                          description: L("Contributes the official Coffic logo to GitOK.")),
                    .init(icon: "highlighter", tint: theme.warning,
                          title: L("Highlight Ready"),
                          description: L("Supports the highlighted state for special moments.")),
                    .init(icon: "square.stack.3d.up", tint: theme.info,
                          title: L("Manager Friendly"),
                          description: L("Registers through the central logo manager."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register"), description: L("The Coffic logo item is registered."), icon: "plus.square"),
                    .init(title: L("Merge"), description: L("The logo manager merges and orders it."), icon: "arrow.triangle.merge"),
                    .init(title: L("Render"), description: L("GitOK draws the Coffic mark."), icon: "photo")
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
    ScrollView { LogoCofficAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
