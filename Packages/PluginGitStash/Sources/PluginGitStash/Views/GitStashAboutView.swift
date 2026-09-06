import LumiUI
import SwiftUI

/// 暂存插件关于视图。
struct GitStashAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "tray.full.fill",
                accent: theme.warning,
                tagline: L("Park your work in progress, pick it up later."),
                chips: [L("Stash"), L("List"), L("Apply")],
                metrics: [
                    .init(value: "1", label: L("click to stash")),
                    .init(value: "∞", label: L("stashes"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "tray.and.arrow.down.fill", tint: theme.warning,
                          title: L("Stash Changes"),
                          description: L("Set aside tracked and untracked work with one click.")),
                    .init(icon: "list.bullet", tint: theme.info,
                          title: L("Stash List"),
                          description: L("Every stash is listed with its message and age.")),
                    .init(icon: "tray.and.arrow.up.fill", tint: theme.success,
                          title: L("Apply & Drop"),
                          description: L("Re-apply a stash to your tree, and drop it when done."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Stash"), description: L("Working changes are saved and the tree is restored."), icon: "tray.and.arrow.down"),
                    .init(title: L("Work elsewhere"), description: L("Switch branches or tasks freely."), icon: "arrow.triangle.branch"),
                    .init(title: L("Restore"), description: L("Apply the stash back and resolve any conflicts."), icon: "tray.and.arrow.up")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitStashLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitStashAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
