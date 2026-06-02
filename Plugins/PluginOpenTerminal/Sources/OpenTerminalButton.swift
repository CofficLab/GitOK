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
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(PluginOpenTerminalLocalization.string("Open in Terminal"))
    }
}
