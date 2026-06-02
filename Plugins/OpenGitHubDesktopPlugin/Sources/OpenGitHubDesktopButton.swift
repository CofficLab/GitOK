import GitOKDesignKit
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
            Image.githubDesktopApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenGitHubDesktopPluginLocalization.string("Open in GitHub Desktop"))
    }
}
