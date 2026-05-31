import GitOKPluginKit
import SwiftUI

public struct OpenTraeButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                TraeProjectLauncher.open(projectURL)
            } label: {
                Image(systemName: "brain")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenTraeLocalization.string("Open in Trae"))
        }
    }
}
