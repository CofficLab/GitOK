import GitOKPluginKit
import SwiftUI

public struct OpenXcodeButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    nonisolated public init() {}

    public var body: some View {
        if let projectURL {
            Button {
                XcodeProjectLauncher.open(projectURL)
            } label: {
                Image(systemName: "hammer")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginOpenXcodeLocalization.string("Open in Xcode"))
        }
    }
}
