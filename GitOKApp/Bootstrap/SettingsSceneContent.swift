import SwiftUI

struct SettingsSceneContent: View {
    private let container = RootContainer.shared

    var body: some View {
        RootView {
            SettingView(defaultTabID: container.appVM.defaultSettingTab ?? "userInfo")
        }
    }
}
