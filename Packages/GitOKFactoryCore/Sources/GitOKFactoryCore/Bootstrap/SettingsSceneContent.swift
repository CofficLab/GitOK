import SwiftUI

public struct SettingsSceneContent: View {
    public init() {}

    private let container = RootContainer.shared

    public var body: some View {
        RootView {
            SettingView(defaultTabID: container.appVM.defaultSettingTab ?? "userInfo")
        }
    }
}
