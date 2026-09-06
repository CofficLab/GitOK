import LumiUI
import SwiftUI

/// LibGit2 后端插件关于视图。
///
/// 通过 LibGit2Swift 内嵌的 C 库执行 Git 操作：无需依赖系统 git，
/// 为 GitOK 提供自包含、可嵌入式的高性能 Git 引擎。
struct GitLibGit2AboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "cube.fill",
                accent: theme.info,
                tagline: L("An embedded Git engine, built into GitOK itself."),
                chips: [L("LibGit2"), L("Self-contained"), L("No system git needed")],
                metrics: [
                    .init(value: "C", label: L("Core engine")),
                    .init(value: "0", label: L("external commands"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "cube.transparent", tint: theme.info,
                          title: L("Embedded Engine"),
                          description: L("LibGit2Swift links the mature libgit2 C library directly into the app.")),
                    .init(icon: "bolt.fill", tint: theme.warning,
                          title: L("High Performance"),
                          description: L("Fast repository operations with tight memory control and no process overhead.")),
                    .init(icon: "shippingbox.fill", tint: theme.success,
                          title: L("Self-Contained"),
                          description: L("Works even when no git binary is installed on the system."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Call the library"), description: L("GitOK requests an operation from the LibGit2Swift API."), icon: "cube.fill"),
                    .init(title: L("Execute in-process"), description: L("libgit2 runs natively in the app process, no subprocess spawning."), icon: "gearshape.2"),
                    .init(title: L("Return structured data"), description: L("The result is handed back to the UI as typed values."), icon: "list.bullet.rectangle")
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
    ScrollView {
        GitLibGit2AboutView()
            .padding(22)
    }
    .frame(width: 560, height: 900)
}
