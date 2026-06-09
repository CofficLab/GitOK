import AppKit
import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenFinderButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            NSWorkspace.shared.activateFileViewerSelecting([projectURL])
        }) {
            Image.finderApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenFinderPluginLocalization.string("Open in Finder"))
    }
}
