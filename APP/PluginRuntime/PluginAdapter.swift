import GitCoreKit
import GitOKCoreKit
import SwiftUI

final class PluginAdapter<Plugin: GitOKPlugin>: GitOKPluginAdapter<Plugin> {
    override func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        AnyView(PackagedPluginRootHost(plugin: plugin, content: content()))
    }
}

struct AppPluginAdapterFactory: GitOKPluginAdapterFactory {
    func makeAdapter<Plugin: GitOKPlugin>(for plugin: Plugin) -> any SuperPlugin {
        PluginAdapter(plugin)
    }
}

private struct PackagedPluginRootHost<Plugin: GitOKPlugin, Content: View>: View {
    let plugin: Plugin
    let content: Content

    @EnvironmentObject private var projectVM: ProjectVM

    var body: some View {
        let base = AnyView(content)
        let context = GitOKPluginContext(
            projectURL: projectVM.project?.url,
            onCleanStatusUpdate: { isClean in
                projectVM.updateIsClean(isClean)
            },
            onGitDirectoryChange: { change in
                postGitDirectoryChange(change)
            },
            onUnpushedCommitsUpdate: { count, hashes in
                projectVM.updateUnpushedCommits(count, hashes: hashes)
            },
            onRemoteTrackingUpdate: { status, fetchedAt in
                if let status {
                    projectVM.updateAheadBehind(
                        GitCoreKit.GitAheadBehind(
                            ahead: status.ahead,
                            behind: status.behind,
                            hasUpstream: status.hasUpstream
                        )
                    )
                } else {
                    projectVM.resetRemoteTrackingState()
                }

                if let fetchedAt {
                    projectVM.updateLastFetchedAt(fetchedAt)
                }
            }
        )
        let wrapped = plugin.rootView(base, context: context) ?? base

        return wrapped
    }

    private func postGitDirectoryChange(_ change: GitOKGitDirectoryChange) {
        guard let project = projectVM.project else { return }
        guard project.url.standardizedFileURL == change.projectURL.standardizedFileURL else { return }

        var additionalInfo: [String: Any] = [
            "gitPath": change.gitDirectoryPath,
            "changeKind": change.changeKind,
            "headChanged": change.headChanged,
            "indexChanged": change.indexChanged,
            "stashChanged": change.stashChanged,
            "refsChanged": change.refsChanged
        ]

        if let previousHead = change.previousHead {
            additionalInfo["previousHead"] = previousHead
        }

        if let head = change.head {
            additionalInfo["head"] = head
        }

        project.postEvent(
            name: .projectGitDirectoryDidChange,
            operation: "gitDirectoryChanged",
            additionalInfo: additionalInfo
        )

        if change.headChanged {
            project.postEvent(name: .projectGitHeadDidChange, operation: "gitHeadChanged", additionalInfo: additionalInfo)
        }

        if change.indexChanged {
            project.postEvent(name: .projectGitIndexDidChange, operation: "gitIndexChanged", additionalInfo: additionalInfo)
        }

        if change.stashChanged {
            project.postEvent(name: .projectGitStashDidChange, operation: "gitStashChanged", additionalInfo: additionalInfo)
        }

        if change.refsChanged {
            project.postEvent(name: .projectGitRefsDidChange, operation: "gitRefsChanged", additionalInfo: additionalInfo)
        }
    }
}
