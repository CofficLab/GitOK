import SwiftUI

public struct OpenKiroButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
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
