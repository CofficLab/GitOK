import AppKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct GitPullButton: View {
    let projectURL: URL
    @State private var isWorking = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            pull(projectURL: projectURL)
        } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .help(PluginGitPullLocalization.string("Pull from remote"))
    }

    private func pull(projectURL: URL) {
        isWorking = true
        Task.detached {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).pull()
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
        alert.messageText = PluginGitPullLocalization.string("Pull failed")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
