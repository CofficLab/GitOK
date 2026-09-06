import LumiUI
import SwiftUI

/// 提交风格设置插件关于视图。
struct GitCommitStyleSettingsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "textformat",
                accent: theme.info,
                tagline: L("Your repository's commit style, enforced consistently."),
                chips: [L("Conventional"), L("Templates"), L("Guides")],
                metrics: [
                    .init(value: "1", label: L("style per repo")),
                    .init(value: "Auto", label: L("guidance"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "textformat.abc", tint: theme.info,
                          title: L("Style Presets"),
                          description: L("Choose Conventional Commits or a custom style.")),
                    .init(icon: "rectangle.and.pencil.and.ellipsis", tint: theme.primary,
                          title: L("Message Templates"),
                          description: L("Define subject and body templates for the commit form.")),
                    .init(icon: "text.badge.checkmark", tint: theme.success,
                          title: L("Live Guidance"),
                          description: L("The form nudges messages toward the chosen style."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Pick a style"), description: L("Set the convention for the repository."), icon: "textformat"),
                    .init(title: L("Shape the form"), description: L("Templates guide subject, body, and trailers."), icon: "rectangle.and.pencil.and.ellipsis"),
                    .init(title: L("Commit cleanly"), description: L("Messages follow the style without friction."), icon: "checkmark.circle")
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
    ScrollView { GitCommitStyleSettingsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
