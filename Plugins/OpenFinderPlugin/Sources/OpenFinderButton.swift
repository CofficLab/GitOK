import AppKit
import SwiftUI

public struct OpenFinderButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([projectURL])
        } label: {
            Image(systemName: "folder")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(OpenFinderPluginLocalization.string("Open in Finder"))
    }
}
