import LumiUI
import SwiftUI

/// 工作树清理插件关于视图。
struct WorktreeCleanAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "bubbles.and.sparkles.fill",
                accent: theme.success,
                tagline: L("Sweep away clutter and keep your repository pristine."),
                chips: [L("Untracked"), L("Ignored"), L("Dry Run")],
                metrics: [
                    .init(value: "0", label: L("risk with dry run")),
                    .init(value: "1", label: L("click to clean"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "eye", tint: theme.info,
                          title: L("Dry Run First"),
                          description: L("Preview every file that would be removed before anything happens.")),
                    .init(icon: "trash", tint: theme.warning,
                          title: L("Untracked Cleanup"),
                          description: L("Remove stray untracked files and directories safely.")),
                    .init(icon: "shield.checkered", tint: theme.success,
                          title: L("Protected by Default"),
                          description: L("Tracked content is never touched, only verified clutter goes."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Analyze"), description: L("Git reports what is untracked or ignored."), icon: "magnifyingglass"),
                    .init(title: L("Preview"), description: L("You review the exact list in a dry run."), icon: "eye"),
                    .init(title: L("Clean"), description: L("Confirm, and the clutter is removed."), icon: "trash")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        WorktreeCleanLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { WorktreeCleanAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
