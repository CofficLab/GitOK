import LumiUI
import SwiftUI

/// 仓库设置插件关于视图。
struct GitRepositorySettingsAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "folder.badge.gearshape",
                accent: theme.primary,
                tagline: L("Fine-tune how GitOK treats each repository."),
                chips: [L("Local config"), L("Per-project"), L("Persistent")],
                metrics: [
                    .init(value: "1", label: L("repo at a time")),
                    .init(value: "Local", label: L("config scope"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "gearshape.2", tint: theme.primary,
                          title: L("Per-Repo Options"),
                          description: L("Customize behavior for the currently open repository.")),
                    .init(icon: "doc.text", tint: theme.info,
                          title: L("Local Git Config"),
                          description: L("Edits apply to the repository's local config file.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.success,
                          title: L("Instant Apply"),
                          description: L("Changes take effect without restarting GitOK."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Open settings"), description: L("Repository settings are scoped to the active project."), icon: "gearshape"),
                    .init(title: L("Edit values"), description: L("Tune repository-specific options."), icon: "square.and.pencil"),
                    .init(title: L("Persist"), description: L("Values are written to the local Git config."), icon: "externaldrive")
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
    ScrollView { GitRepositorySettingsAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
