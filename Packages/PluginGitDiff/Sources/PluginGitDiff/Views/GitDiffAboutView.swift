import LumiUI
import SwiftUI

/// 差异视图插件关于视图。
struct GitDiffAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "equal.circle",
                accent: theme.info,
                tagline: L("Diff made legible — hunk by hunk, line by line."),
                chips: [L("Inline"), L("Side-by-side"), L("Word-level")],
                metrics: [
                    .init(value: "2", label: L("view modes")),
                    .init(value: "Full", label: L("granularity"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "rectangle.split.2x1", tint: theme.info,
                          title: L("Side-by-Side"),
                          description: L("Compare old and new content in parallel columns.")),
                    .init(icon: "text.alignleft", tint: theme.primary,
                          title: L("Word Highlight"),
                          description: L("Intra-line changes are highlighted, not just whole lines.")),
                    .init(icon: "arrow.up.and.down.text.horizontal", tint: theme.warning,
                          title: L("Hunk Navigation"),
                          description: L("Jump between every changed hunk with one key."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Request the diff"), description: L("Any view asks for a diff between two refs or files."), icon: "equal.circle"),
                    .init(title: L("Parse hunks"), description: L("Git's diff output is split into structured hunks."), icon: "arrow.up.and.down.text.horizontal"),
                    .init(title: L("Render"), description: L("Hunks render inline or side-by-side with highlights."), icon: "rectangle.split.2x1")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitDiffLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitDiffAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
