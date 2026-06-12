import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenGitHubDesktopButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            GitHubDesktopProjectLauncher.open(projectURL)
        }) {
            Image.githubDesktopApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenGitHubDesktopPluginLocalization.string("Open in GitHub Desktop"))
    }
}
