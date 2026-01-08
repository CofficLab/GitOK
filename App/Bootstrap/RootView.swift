
import SwiftData
import MagicAlert
import SwiftUI
import MagicKit

struct RootView<Content>: View, SuperEvent where Content: View {
    var content: Content
    var a: AppProvider
    var i: IconProvider
    var p: PluginProvider

    private var box: RootBox

    @StateObject var m = MagicMessageProvider.shared

    init(@ViewBuilder content: () -> Content) {
        self.content = content()

        self.box = RootBox.shared
        self.a = box.app
        self.i = box.icon
        self.p = box.pluginProvider
    }

    var body: some View {
        content
            .withMagicToast()
            .environmentObject(a)
            .environmentObject(i)
            .environmentObject(p)
            .environmentObject(m)
            .environmentObject(self.box.git)
            .navigationTitle("")
    }
}

extension View {
    /// 将当前视图包裹在RootView中
    /// - Returns: 被RootView包裹的视图
    func inRootView() -> some View {
        RootView {
            self
        }
    }
} 

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
