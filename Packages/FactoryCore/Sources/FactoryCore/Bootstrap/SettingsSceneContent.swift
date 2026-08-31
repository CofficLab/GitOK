import KernelCore
import SwiftUI

public struct SettingsSceneContent: View {
    private let kernel: KernelCoreContainer

    public init(kernel: KernelCoreContainer) {
        self.kernel = kernel
    }

    public var body: some View {
        RootView(kernel: kernel) {
            SettingView(
                defaultTabID: kernel.resolveProvider(AppVM.self)?.defaultSettingTab ?? "userInfo"
            )
        }
    }
}
