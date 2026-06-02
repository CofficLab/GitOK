import AppKit
import GitOKDesignKit
import SwiftUI

public struct OpenTerminalButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            TerminalLauncher.open(projectURL)
        } label: {
            Image.terminalRealApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenTerminalPluginLocalization.string("Open in Terminal"))
    }
}
