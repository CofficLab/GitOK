import LumiUI
import SwiftUI

/// 克隆仓库插件关于视图。
struct CloneRepositoryAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.down.circle.fill",
                accent: theme.info,
                tagline: L("Bring any repository into GitOK in seconds."),
                chips: [L("HTTPS & SSH"), L("Progress"), L("Open after clone")],
                metrics: [
                    .init(value: "1", label: L("URL to start")),
                    .init(value: "Live", label: L("progress"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "network", tint: theme.info,
                          title: L("Any Remote URL"),
                          description: L("Clone over HTTPS or SSH from GitHub, GitLab, Gitee, and more.")),
                    .init(icon: "gauge.with.dots.needle.50percent", tint: theme.success,
                          title: L("Live Progress"),
                          description: L("See the transfer in real time with status and error feedback.")),
                    .init(icon: "folder.badge.plus", tint: theme.primary,
                          title: L("Open on Finish"),
                          description: L("The cloned project lands in your list and opens immediately."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Paste the URL"), description: L("Enter an HTTPS or SSH clone URL."), icon: "link"),
                    .init(title: L("Choose a location"), description: L("Pick where the folder should live on disk."), icon: "folder"),
                    .init(title: L("Clone & open"), description: L("GitOK clones with live progress, then adds and opens the project."), icon: "arrow.down.circle")
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
    ScrollView { CloneRepositoryAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
