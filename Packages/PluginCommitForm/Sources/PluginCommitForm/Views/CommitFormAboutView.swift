import LumiUI
import SwiftUI

/// 提交表单插件关于视图。
struct CommitFormAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "square.and.pencil",
                accent: theme.primary,
                tagline: L("Write great commits without leaving the keyboard."),
                chips: [L("Conventional"), L("Auto summary"), L("Safe")],
                metrics: [
                    .init(value: "1", label: L("click to commit")),
                    .init(value: "100%", label: L("coverage"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "textformat.abc", tint: theme.primary,
                          title: L("Message Editor"),
                          description: L("Subject, body, and trailers with live length guidance.")),
                    .init(icon: "sparkles", tint: theme.info,
                          title: L("Conventional Style"),
                          description: L("Type, scope, and summary templates follow Conventional Commits.")),
                    .init(icon: "shield", tint: theme.success,
                          title: L("What You See"),
                          description: L("The exact staged content is shown before you commit."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Stage"), description: L("Pick the changes to include in this commit."), icon: "plus.square"),
                    .init(title: L("Write the message"), description: L("Craft a subject, body, and any trailers."), icon: "square.and.pencil"),
                    .init(title: L("Commit"), description: L("GitOK runs the commit and refreshes the tree."), icon: "checkmark.circle")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        CommitFormLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { CommitFormAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
