import GitOKCoreKit
import SwiftUI

public struct GitClonePlugin: GitOKPlugin {
    public static let shared = GitClonePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitClonePlugin",
        displayName: PluginGitCloneLocalization.string("Clone Repository"),
        description: PluginGitCloneLocalization.string("Clone a Git repository from a remote URL and automatically add it to the project list."),
        iconName: "square.and.arrow.down",
        order: 11,
        policy: .disabled,
        tableName: PluginGitCloneLocalization.table
    )

    private init() {}

    @MainActor
    public func toolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        guard context.canCloneRepository else { return nil }
        return AnyView(GitCloneToolbarButton(context: context))
    }
}

private struct GitCloneToolbarButton: View {
    let context: GitOKPluginContext

    @State private var isShowingCloneSheet = false

    var body: some View {
        Button {
            isShowingCloneSheet = true
        } label: {
            Label(GitClonePlugin.metadata.displayName, systemImage: GitClonePlugin.metadata.iconName)
        }
        .help(GitClonePlugin.metadata.displayName)
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositorySheet(context: context)
        }
    }
}
