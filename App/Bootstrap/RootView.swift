
import SwiftData
import MagicAlert
import SwiftUI
import MagicKit

/// 根视图容器组件
/// 为应用提供统一的上下文环境，包括数据提供者、图标提供者和插件提供者
struct RootView<Content>: View, SuperEvent, SuperLog where Content: View {
    /// 日志标识符
    nonisolated static let emoji = "🏠"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 视图内容
    var content: Content

    /// 应用提供者
    var a: AppProvider

    /// 图标提供者
    var i: IconProvider

    /// 插件提供者
    var p: PluginProvider

    /// 根视图容器
    private var box: RootBox

    /// 消息提供者
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
