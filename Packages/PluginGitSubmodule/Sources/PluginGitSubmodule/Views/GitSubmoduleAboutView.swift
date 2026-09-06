import LumiUI
import SwiftUI

/// 子模块插件关于视图。
struct GitSubmoduleAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "square.stack.3d.up.fill",
                accent: theme.info,
                tagline: L("Nested repositories, managed with care."),
                chips: [L("Add"), L("Update"), L("Status")],
                metrics: [
                    .init(value: "1", label: L("click to add")),
                    .init(value: "Full", label: L("submodule control"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "plus.square.fill", tint: theme.info,
                          title: L("Add Submodule"),
                          description: L("Nest an external repository at any path.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.warning,
                          title: L("Sync & Update"),
                          description: L("Pull registered submodules to the recorded commit.")),
                    .init(icon: "list.bullet", tint: theme.success,
                          title: L("Status Overview"),
                          description: L("See which submodules are out of date or dirty."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Register"), description: L("A submodule is added to the index and .gitmodules."), icon: "square.stack.3d.up"),
                    .init(title: L("Initialize"), description: L("The nested repository is fetched on demand."), icon: "arrow.down.circle"),
                    .init(title: L("Track & update"), description: L("Commits pin the submodule; updates move it forward."), icon: "arrow.triangle.2.circlepath")
                ])
            }
            .landingAppear(delay: 0.1)
        }
    }

    private func L(_ key: String) -> String {
        GitSubmoduleLocalization.string(key, bundle: .module)
    }
}

#Preview {
    ScrollView { GitSubmoduleAboutView().padding(22) }
        .frame(width: 560, height: 900)
}
