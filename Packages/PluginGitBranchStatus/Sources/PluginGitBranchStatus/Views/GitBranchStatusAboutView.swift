import LumiUI
import SwiftUI

/// 分支状态插件关于视图。
struct GitBranchStatusAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.triangle.branch",
                accent: theme.primary,
                tagline: L("Where you are, and where you stand — always visible."),
                chips: [L("Branch"), L("Ahead"), L("Behind")],
                metrics: [
                    .init(value: "1", label: L("glance")),
                    .init(value: "Live", label: L("position"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "arrow.triangle.branch", tint: theme.primary,
                          title: L("Current Branch"),
                          description: L("The active branch name is always in view.")),
                    .init(icon: "arrow.up", tint: theme.warning,
                          title: L("Unpushed Count"),
                          description: L("How many local commits wait on the remote.")),
                    .init(icon: "arrow.down", tint: theme.info,
                          title: L("Unpulled Count"),
                          description: L("How many remote commits you have not pulled yet."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Read HEAD"), description: L("The current branch and ref are resolved."), icon: "arrow.triangle.branch"),
                    .init(title: L("Compare remotes"), description: L("Local and remote refs are compared."), icon: "arrow.up.arrow.down"),
                    .init(title: L("Render status"), description: L("Branch and counts appear in the status bar."), icon: "rectangle.bottomthird.inset.filled")
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
    ScrollView { GitBranchStatusAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
