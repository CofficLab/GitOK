import GitOKPluginKit
import SwiftUI

public struct OpenAntigravityButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
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
}
