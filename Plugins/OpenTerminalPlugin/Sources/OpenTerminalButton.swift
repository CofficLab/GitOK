import AppKit
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
            Image(systemName: "terminal")
                .frame(width: 24)
        }
        .help(OpenTerminalPluginLocalization.string("Open in Terminal"))
    }
}
