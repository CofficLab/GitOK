import SwiftData
import MagicAlert
import SwiftUI
import MagicKit
import OSLog

/// 根视图容器组件
/// 为应用提供统一的上下文环境，包括数据提供者、图标提供者和插件提供者
struct RootView<Content>: View, SuperEvent, SuperLog where Content: View {

    /// 日志标识符
    static var emoji: String { "🚉" }

    /// 是否启用详细日志输出
    static var verbose: Bool { false }

    /// 视图内容
    var content: Content

    /// 应用提供者
    var appProvider: AppProvider

    /// 图标提供者
    var iconProvider: IconProvider

    /// 插件提供者
    var pluginProvider: PluginProvider

    /// Git 数据提供者
    var git: DataProvider

    /// 仓库管理器
    private let repoManager: RepoManager

    /// 消息提供者
    @StateObject var messageProvider = MagicMessageProvider.shared

    init(@ViewBuilder content: () -> Content) {
        self.content = content()

        let c = AppConfig.getContainer()
        self.repoManager = RepoManager(modelContext: ModelContext(c))

        // 初始化提供者
        self.appProvider = AppProvider(repoManager: self.repoManager)
        self.iconProvider = IconProvider()
        self.pluginProvider = PluginProvider()

        // 初始化数据提供者
        do {
            let projects = try self.repoManager.projectRepo.findAll(sortedBy: .ascending)
            self.git = DataProvider(projects: projects, repoManager: self.repoManager)
        } catch let e {
            os_log(.error, "\(Self.t) Failed to load projects: \(e.localizedDescription)")
            self.git = DataProvider(projects: [], repoManager: self.repoManager)
        }
    }

    var body: some View {
        content
            .withMagicToast()
            .environmentObject(appProvider)
            .environmentObject(iconProvider)
            .environmentObject(pluginProvider)
            .environmentObject(messageProvider)
            .environmentObject(git)
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
