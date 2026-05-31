import GitOKPluginKit
import SwiftUI

public struct OpenGitHubDesktopButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                GitHubDesktopProjectLauncher.open(projectURL)
            } label: {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenGitHubDesktopLocalization.string("Open in GitHub Desktop"))
        }
    }
}
