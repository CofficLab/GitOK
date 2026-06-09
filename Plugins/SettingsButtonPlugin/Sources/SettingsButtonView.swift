import Foundation
import GitOKCoreKit
import SwiftUI

public struct SettingsButtonView: View {
    nonisolated public init() {}

    public var body: some View {
        AppStatusBarTile(systemImage: "gearshape", action: {
            NotificationCenter.default.post(name: .gitOKOpenSettings, object: nil)
        })
        .help(SettingsButtonPluginLocalization.string("Open Settings"))
    }
}

public extension Notification.Name {
    static let gitOKOpenSettings = Notification.Name("openSettings")
}
