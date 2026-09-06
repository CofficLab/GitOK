import LumiUI
import SwiftUI

/// 提交详情插件关于视图。
struct CommitDetailAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "doc.text.magnifyingglass",
                accent: theme.warning,
                tagline: L("Every commit, explained down to the last line."),
                chips: [L("Diff"), L("Metadata"), L("Files")],
                metrics: [
                    .init(value: "1", label: L("click from list")),
                    .init(value: "Full", label: L("diff"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "equal.square", tint: theme.info,
                          title: L("Complete Diff"),
                          description: L("See every file change with precise additions and deletions.")),
                    .init(icon: "person.crop.circle", tint: theme.primary,
                          title: L("Rich Metadata"),
                          description: L("Author, committer, timestamps, and full message at a glance.")),
                    .init(icon: "doc.on.doc", tint: theme.warning,
                          title: L("File Navigator"),
                          description: L("Jump between changed files in the commit instantly."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Pick a commit"), description: L("Select any row in the commit list."), icon: "list.bullet.rectangle"),
                    .init(title: L("Load the diff"), description: L("The commit's parents are diffed to build the change set."), icon: "equal.square"),
                    .init(title: L("Inspect"), description: L("Browse files, hunks, and metadata in the detail pane."), icon: "doc.text.magnifyingglass")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        CommitDetailLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { CommitDetailAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
