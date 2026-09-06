import LumiUI
import SwiftUI

/// Git 用户设置插件关于视图。
struct GitUserSettingsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "person.crop.circle.badge.checkmark",
                accent: theme.primary,
                tagline: L("Your Git identity, set once, used everywhere."),
                chips: [L("Name"), L("Email"), L("Signing")],
                metrics: [
                    .init(value: "2", label: L("fields")),
                    .init(value: "1", label: L("identity"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "person.text.rectangle", tint: theme.primary,
                          title: L("Author Identity"),
                          description: L("Configure the name and email used on every commit.")),
                    .init(icon: "checkmark.seal", tint: theme.success,
                          title: L("Commit Signing"),
                          description: L("Optionally sign commits with your GPG or SSH key.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.info,
                          title: L("Repo Overrides"),
                          description: L("Per-repository identities override the global default."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Edit settings"), description: L("Update name, email, or signing key."), icon: "square.and.pencil"),
                    .init(title: L("Write config"), description: L("Git config is updated safely."), icon: "gearshape"),
                    .init(title: L("Commit with identity"), description: L("New commits carry the configured author."), icon: "person.crop.circle")
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
    ScrollView { GitUserSettingsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
