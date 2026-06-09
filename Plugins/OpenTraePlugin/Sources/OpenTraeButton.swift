import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenTraeButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            TraeProjectLauncher.open(projectURL)
        }) {
            Image.traeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenTraePluginLocalization.string("Open in Trae"))
    }
}
