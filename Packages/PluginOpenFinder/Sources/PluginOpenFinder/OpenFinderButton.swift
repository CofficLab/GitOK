import AppKit
import GitOKPluginKit
import SwiftUI

public struct OpenFinderButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([projectURL])
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenFinderLocalization.string("Open in Finder"))
        }
    }
}
