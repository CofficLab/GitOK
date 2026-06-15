import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenTerminalButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            TerminalLauncher.open(projectURL)
        }) {
            Image.terminalApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenTerminalPluginLocalization.string("Open in Terminal"))
    }
}
