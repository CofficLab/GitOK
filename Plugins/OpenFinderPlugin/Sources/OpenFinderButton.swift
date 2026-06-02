import AppKit
import GitOKDesignKit
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
            Image.finderApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenFinderPluginLocalization.string("Open in Finder"))
    }
}
