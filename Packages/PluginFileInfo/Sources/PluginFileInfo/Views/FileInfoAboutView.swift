import LumiUI
import SwiftUI

/// 文件信息插件关于视图。
struct FileInfoAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "doc.text.magnifyingglass",
                accent: theme.info,
                tagline: L("Every file's story, at your fingertips."),
                chips: [L("Changes"), L("Blame"), L("Status")],
                metrics: [
                    .init(value: "1", label: L("selection")),
                    .init(value: "Full", label: L("history"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "clock.arrow.circlepath", tint: theme.primary,
                          title: L("File History"),
                          description: L("Every commit that touched the selected file, newest first.")),
                    .init(icon: "person.3.sequence.fill", tint: theme.warning,
                          title: L("Blame"),
                          description: L("See who changed each line and when.")),
                    .init(icon: "info.circle", tint: theme.success,
                          title: L("Rich Status"),
                          description: L("Tracked, staged, modified, or untracked — always clear."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Select a file"), description: L("Pick any file in the worktree view."), icon: "doc"),
                    .init(title: L("Query git"), description: L("Log, status, and blame are gathered for the path."), icon: "magnifyingglass"),
                    .init(title: L("Present"), description: L("History and blame render beside the file."), icon: "doc.text.magnifyingglass")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        FileInfoLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { FileInfoAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
