import GitOKPluginKit
import SwiftUI

public struct OpenVSCodeButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                VSCodeProjectLauncher.open(projectURL)
            } label: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenVSCodeLocalization.string("Open in VS Code"))
        }
    }
}
