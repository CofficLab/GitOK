import GitOKPluginKit
import SwiftUI

public struct OpenKiroButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                KiroProjectLauncher.open(projectURL)
            } label: {
                Image(systemName: "water.waves")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenKiroLocalization.string("Open in Kiro"))
        }
    }
}
