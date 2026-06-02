import Foundation
import SwiftUI

public struct SettingsButtonView: View {
    nonisolated public init() {}

    public var body: some View {
        Button {
            NotificationCenter.default.post(name: .gitOKOpenSettings, object: nil)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(PluginSettingsButtonLocalization.string("Open Settings"))
    }
}

public extension Notification.Name {
    static let gitOKOpenSettings = Notification.Name("openSettings")
}
