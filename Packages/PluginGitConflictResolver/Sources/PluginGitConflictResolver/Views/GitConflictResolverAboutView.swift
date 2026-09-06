import LumiUI
import SwiftUI

/// 冲突解决插件关于视图。
struct GitConflictResolverAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.triangle.2.circlepath.circle.fill",
                accent: theme.warning,
                tagline: L("Conflicts resolved with clarity, not guesswork."),
                chips: [L("Ours"), L("Theirs"), L("Both")],
                metrics: [
                    .init(value: "3", label: L("resolution choices")),
                    .init(value: "1", label: L("click to resolve"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "person.fill", tint: theme.info,
                          title: L("Keep Ours"),
                          description: L("Take the current branch's version of the conflict.")),
                    .init(icon: "person.2.fill", tint: theme.primary,
                          title: L("Keep Theirs"),
                          description: L("Take the incoming branch's version.")),
                    .init(icon: "doc.on.doc.fill", tint: theme.success,
                          title: L("Merge Manually"),
                          description: L("Open the conflicted file and craft the final content."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Detect"), description: L("Conflicted files are detected across the repository."), icon: "exclamationmark.triangle"),
                    .init(title: L("Choose"), description: L("Pick ours, theirs, or edit by hand."), icon: "arrow.triangle.2.circlepath"),
                    .init(title: L("Stage the result"), description: L("The resolution is staged and marked resolved."), icon: "checkmark.circle")
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
    ScrollView { GitConflictResolverAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
