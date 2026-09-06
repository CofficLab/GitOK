import LumiUI
import SwiftUI

/// .gitignore 插件关于视图。
struct GitIgnoreAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "line.3.horizontal.decrease.circle.fill",
                accent: theme.primary,
                tagline: L("Keep noise out of your repository, effortlessly."),
                chips: [L("Templates"), L("Live preview"), L("Per-path")],
                metrics: [
                    .init(value: "1", label: L("file to rule them")),
                    .init(value: "∞", label: L("templates"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "text.book.closed.fill", tint: theme.info,
                          title: L("Template Library"),
                          description: L("Start from curated templates for common languages and tools.")),
                    .init(icon: "eye", tint: theme.success,
                          title: L("Live Preview"),
                          description: L("See which files would be ignored as you edit the rules.")),
                    .init(icon: "line.3.horizontal.decrease", tint: theme.warning,
                          title: L("Nested Rules"),
                          description: L("Repo-level and global ignore rules are respected together."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Edit rules"), description: L("Add patterns to .gitignore."), icon: "square.and.pencil"),
                    .init(title: L("Evaluate"), description: L("Git re-reads the rules against the working tree."), icon: "checkmark.shield"),
                    .init(title: L("Stay clean"), description: L("Matching files disappear from untracked status."), icon: "line.3.horizontal.decrease.circle")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitIgnoreLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitIgnoreAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
