import SwiftUI

public struct SettingsSceneContent: View {
    public init() {}

    private var container: RootContainer { RootContainer.shared }

    public var body: some View {
        RootView {
            SettingView(defaultTabID: container.appVM.defaultSettingTab ?? "userInfo")
        }
    }
}
