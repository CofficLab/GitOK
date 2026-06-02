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
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(PluginOpenCursorLocalization.string("Open in Cursor"))
    }
}
