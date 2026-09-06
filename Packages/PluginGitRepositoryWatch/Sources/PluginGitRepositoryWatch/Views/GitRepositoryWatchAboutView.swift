import LumiUI
import SwiftUI

/// Git 仓库监听插件关于视图。
///
/// 基于文件系统事件（FSEvents）监听当前项目的 `.git` 目录，
/// 外部改动（终端 git 操作、其他工具修改仓库）会立即广播给各消费方。
struct GitRepositoryWatchAboutView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LandingHero(
                icon: "waveform.path.ecg",
                accent: theme.success,
                tagline: L("See repository changes the moment they happen — even from outside GitOK."),
                chips: [L("FSEvents"), L("Live"), L("External changes")],
                metrics: [
                    .init(value: "Live", label: L("monitoring")),
                    .init(value: ".git", label: L("watch target"))
                ]
            )
            .landingAppear()

            LandingSection(title: L("Core Capabilities"), icon: "square.grid.2x2") {
                LandingFeatureGrid(items: [
                    .init(icon: "eye.fill", tint: theme.success,
                          title: L("True File Watching"),
                          description: L("Monitors the real .git directory with file system events, not polling.")),
                    .init(icon: "arrow.triangle.2.circlepath", tint: theme.warning,
                          title: L("External Awareness"),
                          description: L("Terminal stash, checkout, or third-party tools instantly refresh the UI.")),
                    .init(icon: "arrow.turn.up.right", tint: theme.info,
                          title: L("Event Broadcast"),
                          description: L("Changes are broadcast per dimension so each view refreshes precisely."))
                ])
            }
            .landingAppear(delay: 0.05)

            LandingSection(title: L("How It Works"), icon: "arrow.triangle.branch.and.merge") {
                LandingStepFlow(steps: [
                    .init(title: L("Follow the project"), description: L("The watcher targets the current project's .git directory."), icon: "folder"),
                    .init(title: L("Listen to the disk"), description: L("FSEventStream reports every change inside .git."), icon: "waveform.path.ecg"),
                    .init(title: L("Broadcast events"), description: L("Commit list, branch status, and workspace views refresh on demand."), icon: "dot.radiowaves.left.and.right")
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
        GitRepositoryWatchAboutView()
            .padding(22)
    }
    .frame(width: 560, height: 900)
}
