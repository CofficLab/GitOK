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
                .frame(width: 24)
        }
        .help(OpenFinderPluginLocalization.string("Open in Finder"))
    }
}
