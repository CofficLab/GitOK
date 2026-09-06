import LumiUI
import SwiftUI

/// 远程仓库插件关于视图。
struct GitRemoteRepositoryAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "arrow.triangle.branch",
                accent: theme.info,
                tagline: L("Remotes managed with full control."),
                chips: [L("Add"), L("Remove"), L("Rename")],
                metrics: [
                    .init(value: "1", label: L("click to add")),
                    .init(value: "∞", label: L("remotes"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "plus.circle", tint: theme.success,
                          title: L("Add Remote"),
                          description: L("Attach new remotes with any name and URL.")),
                    .init(icon: "pencil.circle", tint: theme.info,
                          title: L("Edit & Rename"),
                          description: L("Update URLs or rename remotes without losing tracking.")),
                    .init(icon: "trash.circle", tint: theme.warning,
                          title: L("Remove Safely"),
                          description: L("Detach remotes with clear confirmation."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("List remotes"), description: L("Current remotes are read from the repo config."), icon: "list.bullet"),
                    .init(title: L("Modify"), description: L("Add, rename, or remove entries."), icon: "square.and.pencil"),
                    .init(title: L("Save config"), description: L("Changes are persisted to the repository."), icon: "externaldrive")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitRemoteRepositoryLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitRemoteRepositoryAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
