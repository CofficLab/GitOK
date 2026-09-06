import LumiUI
import SwiftUI

/// 工作树状态插件关于视图。
struct WorktreeStatusAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.triangle.branch",
                accent: theme.success,
                tagline: L("See exactly what changed in your working tree."),
                chips: [L("Changed"), L("Staged"), L("Untracked")],
                metrics: [
                    .init(value: "3", label: L("change kinds")),
                    .init(value: "Live", label: L("refresh"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "pencil", tint: theme.warning,
                          title: L("Modified Files"),
                          description: L("Tracked files with uncommitted changes appear instantly.")),
                    .init(icon: "plus.circle.fill", tint: theme.success,
                          title: L("Untracked Files"),
                          description: L("New files show up until you decide to track or ignore them.")),
                    .init(icon: "checkmark.circle.fill", tint: theme.info,
                          title: L("Staged Changes"),
                          description: L("The index state is shown separately from working-tree edits."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Scan the tree"), description: L("Git compares working tree and index against HEAD."), icon: "arrow.triangle.branch"),
                    .init(title: L("Categorize"), description: L("Files are grouped by modified, staged, or untracked."), icon: "square.3.layers.3d"),
                    .init(title: L("Refresh live"), description: L("File events re-scan the tree and update the list."), icon: "arrow.clockwise")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        WorktreeStatusLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { WorktreeStatusAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
