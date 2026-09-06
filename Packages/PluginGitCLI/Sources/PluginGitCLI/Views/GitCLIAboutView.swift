import LumiUI
import SwiftUI

/// Git CLI 后端插件关于视图。
///
/// 通过系统 `git` 命令行提供全部 Git 操作：稳定、兼容性好，
/// 支持系统已安装的任何 git 版本与扩展配置。
struct GitCLIAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "terminal",
                accent: theme.primary,
                tagline: L("Drive every Git operation through the system git command."),
                chips: [L("System git"), L("Battle-tested"), L("Zero install")],
                metrics: [
                    .init(value: "100%", label: L("git compatibility")),
                    .init(value: "0", label: L("extra dependencies"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "checkmark.circle", tint: theme.success,
                          title: L("Full Git Surface"),
                          description: L("Commit, branch, diff, stash, and more — all through the git command line.")),
                    .init(icon: "wand.and.stars", tint: theme.info,
                          title: L("System Integration"),
                          description: L("Honors your global git config, hooks, credential helpers, and SSH setup.")),
                    .init(icon: "shield.lefthalf.filled", tint: theme.warning,
                          title: L("Reliable"),
                          description: L("The same battle-tested engine used by millions of developers every day."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Issue a command"), description: L("GitOK translates every action into a precise git invocation."), icon: "text.badge.checkmark"),
                    .init(title: L("Run git"), description: L("The system git binary executes with the repository as its working directory."), icon: "terminal"),
                    .init(title: L("Parse the result"), description: L("GitOK turns the output into structured data for the UI."), icon: "list.bullet.rectangle")
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
        GitCLIAboutView()
            .padding(22)
    }
    .frame(width: 560, height: 900)
}
