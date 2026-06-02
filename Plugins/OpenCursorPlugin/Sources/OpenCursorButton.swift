import GitOKDesignKit
import SwiftUI

public struct OpenCursorButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            CursorProjectLauncher.open(projectURL)
        } label: {
            Image.cursorApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenCursorPluginLocalization.string("Open in Cursor"))
    }
}
