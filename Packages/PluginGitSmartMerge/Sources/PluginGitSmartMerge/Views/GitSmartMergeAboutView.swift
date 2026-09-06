import LumiUI
import SwiftUI

/// 智能合并插件关于视图。
struct GitSmartMergeAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.triangle.merge",
                accent: theme.info,
                tagline: L("Merges that understand your branches."),
                chips: [L("Conflict-aware"), L("Safe"), L("Reversible")],
                metrics: [
                    .init(value: "1", label: L("click to merge")),
                    .init(value: "Low", label: L("conflict risk"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "arrow.triangle.branch", tint: theme.primary,
                          title: L("Branch Aware"),
                          description: L("Understands where your branches diverged and why.")),
                    .init(icon: "exclamationmark.arrow.triangle.2.circlepath", tint: theme.warning,
                          title: L("Conflict Detection"),
                          description: L("Potential conflicts are flagged before you commit to the merge.")),
                    .init(icon: "arrow.uturn.backward.circle", tint: theme.success,
                          title: L("Reversible"),
                          description: L("Merges can be abandoned cleanly if something feels wrong."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Analyze"), description: L("The divergence between branches is computed."), icon: "arrow.triangle.branch"),
                    .init(title: L("Merge"), description: L("Git performs the merge with your chosen strategy."), icon: "arrow.triangle.merge"),
                    .init(title: L("Resolve & verify"), description: L("Conflicts are listed for resolution; the tree is verified."), icon: "checkmark.seal")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitSmartMergeLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitSmartMergeAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
