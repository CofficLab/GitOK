import GitOKUI
import SwiftUI

public struct OpenTerminalButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(systemImage: "terminal", action: {
            TerminalLauncher.open(projectURL)
        })
        .help(OpenTerminalPluginLocalization.string("Open in Terminal"))
    }
}
