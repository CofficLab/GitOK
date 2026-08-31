import Foundation
import KitGitOKCore
import SwiftUI

public struct SettingsButtonView: View {
    private let onOpenSettings: () -> Void

    public init(onOpenSettings: @escaping () -> Void = {}) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        AppStatusBarTile(systemImage: "gearshape", action: onOpenSettings)
            .help(SettingsButtonPluginLocalization.string("Open Settings"))
    }
}
