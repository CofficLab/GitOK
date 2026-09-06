import LumiUI
import SwiftUI

/// 提交列表插件关于视图。
struct CommitListAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "list.bullet.rectangle",
                accent: theme.primary,
                tagline: L("The full story of your repository, in one list."),
                chips: [L("All branches"), L("Live"), L("Searchable")],
                metrics: [
                    .init(value: "∞", label: L("commits")),
                    .init(value: "Live", label: L("updates"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "rectangle.stack", tint: theme.primary,
                          title: L("Full History"),
                          description: L("Browse the complete commit log across the current branch.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.warning,
                          title: L("Live Refresh"),
                          description: L("New commits appear the moment the repository changes.")),
                    .init(icon: "text.magnifyingglass", tint: theme.info,
                          title: L("Search & Filter"),
                          description: L("Filter by message, author, or time range in an instant."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Walk the log"), description: L("Git walks commits from HEAD back through history."), icon: "list.bullet.rectangle"),
                    .init(title: L("Decorate"), description: L("Branches, tags, and authors enrich each row."), icon: "tag"),
                    .init(title: L("Select & inspect"), description: L("Clicking a commit opens its detail view."), icon: "arrow.right.circle")
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
    ScrollView { CommitListAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
