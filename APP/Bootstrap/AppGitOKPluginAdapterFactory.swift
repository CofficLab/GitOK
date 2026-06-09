import BannerPlugin
import GitOKCoreKit
import IconPlugin
import SwiftUI

@MainActor
struct AppGitOKPluginAdapterFactory: GitOKPluginAdapterFactory {
    func makeAdapter<Plugin: GitOKPlugin>(for plugin: Plugin) -> any SuperPlugin {
        switch Plugin.metadata.id {
        case "BannerPlugin":
            GitOKPluginAdapter(
                plugin,
                detailViewProvider: { tab, context in
                    guard tab == "Banner" else { return nil }
                    return AnyView(
                        BannerDetailLayout(projectURL: context.projectURL)
                            .environmentObject(BannerProvider.shared)
                    )
                }
            )
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
        case "IconPlugin":
            GitOKPluginAdapter(
                plugin,
                detailViewProvider: { tab, context in
                    guard tab == "Icon" else { return nil }
                    return AnyView(
                        IconDetailLayout(projectURL: context.projectURL)
                            .environmentObject(IconProvider())
                    )
                }
            )
        default:
            GitOKPluginAdapter(plugin)
        }
    }
}
