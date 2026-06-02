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
                .frame(width: 24)
        }
        .help(OpenGitHubDesktopPluginLocalization.string("Open in GitHub Desktop"))
    }
}
