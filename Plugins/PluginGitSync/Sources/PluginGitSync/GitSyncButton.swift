import AppKit
import GitCoreKit
import SwiftUI

public struct GitSyncButton: View {
    let projectURL: URL
    @State private var isWorking = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            sync(projectURL: projectURL)
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .help(PluginGitSyncLocalization.string("Sync with remote repository"))
    }

    private func sync(projectURL: URL) {
        isWorking = true
        Task.detached {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let remotes = try repository.remoteNames()
                guard !remotes.isEmpty else {
                    throw NSError(
                        domain: "PluginGitSync",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: PluginGitSyncLocalization.string("No remote repository configured")]
                    )
                }

                try repository.sync()
                await MainActor.run {
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    showError(error)
                }
            }
        }
    }

    @MainActor
    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = PluginGitSyncLocalization.string("Sync failed")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
