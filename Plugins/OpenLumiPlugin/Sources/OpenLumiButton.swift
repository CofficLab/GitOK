import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenLumiButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            LumiProjectLauncher.open(projectURL)
        }) {
            Image.lumiApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenLumiPluginLocalization.string("Open in Lumi"))
    }
}
