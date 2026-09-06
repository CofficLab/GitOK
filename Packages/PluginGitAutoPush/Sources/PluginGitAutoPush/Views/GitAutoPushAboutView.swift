import LumiUI
import SwiftUI

/// 自动推送插件关于视图。
struct GitAutoPushAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "paperplane.fill",
                accent: theme.success,
                tagline: L("Your commits travel to the remote on their own."),
                chips: [L("Automatic"), L("Configurable"), L("Safe")],
                metrics: [
                    .init(value: "0", label: L("manual pushes")),
                    .init(value: "Auto", label: L("sync"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "paperplane", tint: theme.success,
                          title: L("Push on Commit"),
                          description: L("New commits are pushed to the tracked remote automatically.")),
                    .init(icon: "switch.2", tint: theme.info,
                          title: L("Per-Project Control"),
                          description: L("Enable or disable auto-push for each repository.")),
                    .init(icon: "shield", tint: theme.warning,
                          title: L("Failure Awareness"),
                          description: L("Failed pushes are surfaced instead of silently retried."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Commit lands"), description: L("A new local commit is created."), icon: "checkmark.circle"),
                    .init(title: L("Push triggers"), description: L("Auto-push runs against the configured remote."), icon: "paperplane"),
                    .init(title: L("Verify"), description: L("The remote ref is confirmed and status updates."), icon: "checkmark.shield")
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
    ScrollView { GitAutoPushAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
