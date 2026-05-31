import SwiftUI

public struct OpenAntigravityButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            AntigravityProjectLauncher.open(projectURL)
        } label: {
            Image(systemName: "paperplane")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(PluginOpenAntigravityLocalization.string("Open in Antigravity"))
    }
}
