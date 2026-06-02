import SwiftUI

public struct OpenGitHubDesktopButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
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
