import AppKit
import GitOKPluginKit
import SwiftUI

public struct OpenTerminalButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
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
}
