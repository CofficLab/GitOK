import GitOKCoreKit
import SwiftUI

@MainActor
final class GitOKAppHostedViewProvider: GitOKAppHostedViewProviding {
    func commitListView(context: GitOKPluginContext) -> AnyView? {
        guard context.isGitRepository else { return nil }
        return AnyView(CommitList())
    }

    func gitDetailView(context: GitOKPluginContext) -> AnyView? {
        AnyView(GitDetail())
    }
}
