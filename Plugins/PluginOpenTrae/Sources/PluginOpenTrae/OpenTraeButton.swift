import SwiftUI

public struct OpenTraeButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
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
