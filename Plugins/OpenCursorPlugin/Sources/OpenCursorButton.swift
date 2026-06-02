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
            Image(systemName: "cursor.rays")
                .frame(width: 24)
        }
        .help(OpenCursorPluginLocalization.string("Open in Cursor"))
    }
}
