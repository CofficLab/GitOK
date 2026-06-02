import GitOKCoreKit
import SwiftUI

@MainActor
struct AppGitOKPluginAdapterFactory: GitOKPluginAdapterFactory {
    func makeAdapter<Plugin: GitOKPlugin>(for plugin: Plugin) -> any SuperPlugin {
        switch Plugin.metadata.id {
        case "CommitPlugin":
            GitOKPluginAdapter(
                plugin,
                listViewProvider: { tab, _, context in
                    guard tab == "Git", context.isGitRepository else { return nil }
                    return AnyView(CommitList())
                }
            )
        case "GitDetailPlugin":
            GitOKPluginAdapter(
                plugin,
                detailViewProvider: { tab, _ in
                    guard tab == "Git" else { return nil }
                    return AnyView(GitDetail())
                }
            )
        default:
            GitOKPluginAdapter(plugin)
        }
    }
}
