import LumiUI
import SwiftUI

/// Git LFS 插件关于视图。
struct GitLFSAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "externaldrive.badge.plus",
                accent: theme.warning,
                tagline: L("Large files, stored smart, cloned fast."),
                chips: [L("LFS"), L("Track"), L("Pointer-based")],
                metrics: [
                    .init(value: "1", label: L("command")),
                    .init(value: "∞", label: L("file size"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "externaldrive", tint: theme.warning,
                          title: L("LFS Backing"),
                          description: L("Large binary content is stored outside the repository.")),
                    .init(icon: "text.badge.checkmark", tint: theme.info,
                          title: L("Track Patterns"),
                          description: L("Declare which file types are managed by LFS.")),
                    .init(icon: "bolt", tint: theme.success,
                          title: L("Fast Clones"),
                          description: L("Repositories stay light — content is pulled on demand."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Track"), description: L("File patterns are marked for LFS."), icon: "plus.circle"),
                    .init(title: L("Commit pointers"), description: L("Git stores a small pointer instead of the payload."), icon: "doc.text"),
                    .init(title: L("Fetch content"), description: L("LFS downloads the real file when you check it out."), icon: "arrow.down.circle")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitLFSLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitLFSAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
