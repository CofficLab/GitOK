import LumiUI
import SwiftUI

/// 提交 toast 插件关于视图。
struct CommitToastAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "checkmark.message.fill",
                accent: theme.success,
                tagline: L("Every commit confirmed the moment it lands."),
                chips: [L("Instant"), L("Actionable"), L("Non-blocking")],
                metrics: [
                    .init(value: "1", label: L("toast per commit")),
                    .init(value: "0", label: L("interruptions"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "bolt.fill", tint: theme.success,
                          title: L("Instant Feedback"),
                          description: L("A short confirmation appears right after each commit.")),
                    .init(icon: "arrow.uturn.backward", tint: theme.warning,
                          title: L("Quick Undo"),
                          description: L("Roll back the last commit directly from the toast.")),
                    .init(icon: "rectangle.compress.vertical", tint: theme.info,
                          title: L("Stay Out of the Way"),
                          description: L("Toasts auto-dismiss and never block your workflow."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Commit succeeds"), description: L("The commit service reports success."), icon: "checkmark.circle"),
                    .init(title: L("Show toast"), description: L("A confirmation toast renders at the top of the window."), icon: "checkmark.message"),
                    .init(title: L("Act or ignore"), description: L("Undo from the toast, or let it fade away."), icon: "arrow.uturn.backward")
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
    ScrollView { CommitToastAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
