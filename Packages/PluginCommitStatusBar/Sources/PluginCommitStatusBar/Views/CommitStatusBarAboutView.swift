import LumiUI
import SwiftUI

/// 提交状态栏插件关于视图。
struct CommitStatusBarAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "checkmark.seal.fill",
                accent: theme.success,
                tagline: L("Your commit health, always visible at the bottom."),
                chips: [L("Clean"), L("Dirty"), L("Ahead/Behind")],
                metrics: [
                    .init(value: "1", label: L("glance")),
                    .init(value: "Live", label: L("status"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "checkmark.circle", tint: theme.success,
                          title: L("Clean Indicator"),
                          description: L("A green mark when the working tree matches HEAD.")),
                    .init(icon: "exclamationmark.circle", tint: theme.warning,
                          title: L("Dirty Indicator"),
                          description: L("Uncommitted changes light up the status bar instantly.")),
                    .init(icon: "arrow.up.arrow.down", tint: theme.info,
                          title: L("Ahead / Behind"),
                          description: L("Unpushed and unpulled counts sit next to the branch."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Read the tree"), description: L("The status service compares tree and index."), icon: "arrow.triangle.branch"),
                    .init(title: L("Update the bar"), description: L("Indicators redraw with the current state."), icon: "rectangle.bottomthird.inset.filled"),
                    .init(title: L("Stay current"), description: L("File events keep the indicator in sync."), icon: "arrow.clockwise")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        CommitStatusBarLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { CommitStatusBarAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
