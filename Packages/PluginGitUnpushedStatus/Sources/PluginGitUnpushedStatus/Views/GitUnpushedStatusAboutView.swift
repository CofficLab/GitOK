import LumiUI
import SwiftUI

/// 未推送状态插件关于视图。
struct GitUnpushedStatusAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.up.circle.fill",
                accent: theme.warning,
                tagline: L("Never lose track of what hasn't reached the remote."),
                chips: [L("Unpushed"), L("Reminder"), L("Per branch")],
                metrics: [
                    .init(value: "N", label: L("unpushed commits")),
                    .init(value: "Live", label: L("tracking"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "arrow.up.circle", tint: theme.warning,
                          title: L("Unpushed Detection"),
                          description: L("Commits that never reached the remote are counted.")),
                    .init(icon: "bell.badge", tint: theme.info,
                          title: L("Gentle Reminders"),
                          description: L("A subtle indicator keeps the state visible.")),
                    .init(icon: "square.stack.3d.up", tint: theme.success,
                          title: L("Per-Branch Clarity"),
                          description: L("Each branch shows its own ahead/behind position."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Compare refs"), description: L("Local branches are compared with their remotes."), icon: "arrow.up.arrow.down"),
                    .init(title: L("Count commits"), description: L("The ahead count is computed per branch."), icon: "number.circle"),
                    .init(title: L("Show reminder"), description: L("The status bar surfaces the unpushed count."), icon: "arrow.up.circle")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitUnpushedStatusLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitUnpushedStatusAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
