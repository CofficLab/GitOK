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
                .frame(width: 24)
        }
        .help(OpenTraePluginLocalization.string("Open in Trae"))
    }
}
