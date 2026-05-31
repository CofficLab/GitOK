import GitOKPluginKit
import SwiftUI

public struct OpenCursorButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
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
}
