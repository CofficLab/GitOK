import GitOKPluginKit
import GitOKUI
import SwiftUI

/// `SuperPlugin` 是 GitOK 应用的插件系统核心协议。
/// 所有插件必须实现此协议以便集成到应用程序中。
///
/// 该协议定义了插件的基本属性和行为，包括：
/// - 插件的标识和显示信息
/// - 插件在不同界面区域的视图渲染方法
/// - 插件的生命周期管理方法
protocol SuperPlugin {
    /// 插件的实例标签，用于在 ForEach 等需要实例属性的地方作为标识符
    /// 默认实现使用反射获取类名
    var instanceLabel: String { get }

    /// 实例级插件注册顺序。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginOrder: Int { get }

    /// 实例级显示名称。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginDisplayName: String { get }

    /// 实例级描述。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginDescription: String { get }

    /// 实例级图标。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginIconName: String { get }

    /// 实例级用户开关能力。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginAllowUserToggle: Bool { get }

    /// 实例级默认启用状态。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginDefaultEnabled: Bool { get }

    /// 实例级多语言表名。默认转发到静态属性，package adapter 可按被包装插件覆盖。
    var pluginTableName: String { get }

    /// 插件注册顺序，数字越小越先注册
    static var order: Int { get }

    /// 插件显示名称
    static var displayName: String { get }

    /// 插件描述
    static var description: String { get }

    /// 插件图标名称
    static var iconName: String { get }

    /// 是否允许用户在设置中切换启用/禁用此插件
    /// 如果为 false，插件始终启用且不在设置中显示
    /// 如果为 true，插件显示在设置中，用户可控制启用状态
    static var allowUserToggle: Bool { get }

    /// 插件默认启用状态（仅在用户未配置时生效）
    /// 如果用户配置过，以用户配置为准
    static var defaultEnabled: Bool { get }

    /// 插件多语言表名，默认为插件类名
    static var tableName: String { get }

    /// 插件是否应该注册到系统中
    /// 开发者可通过此属性控制插件是否启用
    static var shouldRegister: Bool { get }

    /// 返回插件的标签项名称，如果插件提供标签页则返回标签名称，否则返回 nil
    func addTabItem() -> String?

    /// 返回插件的列表视图
    /// - Parameters:
    ///   - tab: 标签页的名称
    ///   - project: 当前的项目
    /// - Returns: 包装在 AnyView 中的列表视图
    func addListView(tab: String, project: Project?) -> AnyView?

    /// 返回插件的详情视图
    /// - Parameter tab: 标签页的名称
    /// - Returns: 包装在 AnyView 中的详情视图
    @MainActor
    func addDetailView(for tab: String) -> AnyView?

    /// 返回插件在工具栏前部区域的视图
    /// - Parameter context: 插件上下文，包含当前项目、分支等运行时状态
    /// - Returns: 包装在 AnyView 中的工具栏前部视图
    @MainActor
    func addToolBarLeadingView(context: GitOKPluginContext) -> AnyView?

    /// 返回插件在工具栏后部区域的视图
    /// - Parameter context: 插件上下文，包含当前项目、分支等运行时状态
    /// - Returns: 包装在 AnyView 中的工具栏后部视图
    @MainActor
    func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView?

    /// 返回插件在状态栏前部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏前部视图
    @MainActor
    func addStatusBarLeadingView(context: GitOKPluginContext) -> AnyView?

    /// 返回插件在状态栏中间区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏中间视图
    @MainActor
    func addStatusBarCenterView(context: GitOKPluginContext) -> AnyView?

    /// 返回插件在状态栏后部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏后部视图
    @MainActor
    func addStatusBarTrailingView(context: GitOKPluginContext) -> AnyView?

    /// 添加根视图包裹
    /// 允许插件包裹整个应用的内容视图，实现全局拦截、修饰等功能。
    /// 此方法在视图层次的最外层执行，可以用于：
    /// - 添加全局 overlay
    /// - 拦截手势事件
    /// - 应用全局样式
    ///
    /// - Parameter content: 要被包裹的原始内容视图
    /// - Returns: 包裹后的视图，如果不需要则返回 nil
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View

    /// 返回插件贡献的应用主题。
    /// 主题插件通过此入口登记主题，宿主负责聚合、排序和选择。
    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution]

    /// 给插件视图注入当前项目 URL。旧插件默认不处理，package adapter 可覆盖。
    func viewWithProjectURL(_ view: AnyView, projectURL: URL?) -> AnyView
}

/// SuperPlugin 协议的默认实现
/// 提供了一些方法的空实现，使插件开发者只需实现他们关心的方法
extension SuperPlugin {
    /// 默认的标签项实现，返回 nil 表示不提供标签页
    func addTabItem() -> String? { nil }

    /// 默认的多语言表名实现，使用反射获取类名
    static var tableName: String {
        let typeName = String(describing: self)
        // 移除模块前缀（例如 "GitOK."）
        if let dotIndex = typeName.lastIndex(of: ".") {
            return String(typeName[typeName.index(after: dotIndex)...]).replacingOccurrences(of: "Plugin", with: "")
        }
        return typeName.replacingOccurrences(of: "Plugin", with: "")
    }

    /// 默认的实例标签实现，使用反射获取类名
    var instanceLabel: String {
        let typeName = String(describing: type(of: self))
        // 移除模块前缀（例如 "GitOK."）
        if let dotIndex = typeName.lastIndex(of: ".") {
            return String(typeName[typeName.index(after: dotIndex)...])
        }
        return typeName
    }

    var pluginOrder: Int { type(of: self).order }

    var pluginDisplayName: String { type(of: self).displayName }

    var pluginDescription: String { type(of: self).description }

    var pluginIconName: String { type(of: self).iconName }

    var pluginAllowUserToggle: Bool { type(of: self).allowUserToggle }

    var pluginDefaultEnabled: Bool { type(of: self).defaultEnabled }

    var pluginTableName: String { type(of: self).tableName }

    /// 默认的注册顺序实现
    static var order: Int {
        return 9999
    }

    /// 默认的显示名称实现，使用反射获取类名
    static var displayName: String {
        let typeName = String(describing: self)
        // 移除模块前缀（例如 "GitOK."）
        if let dotIndex = typeName.lastIndex(of: ".") {
            return String(typeName[typeName.index(after: dotIndex)...])
        }
        return typeName
    }

    /// 默认的插件描述实现，返回空字符串
    static var description: String {
        return ""
    }

    /// 默认的图标名称实现
    static var iconName: String {
        return "puzzlepiece.extension"
    }

    /// 默认允许用户切换
    static var allowUserToggle: Bool { true }

    /// 默认应该注册
    static var shouldRegister: Bool { true }

    /// 默认启用插件
    static var defaultEnabled: Bool { true }

    /// 默认的工具栏前部视图实现，返回空视图
    @MainActor
    func addToolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    /// 默认的工具栏后部视图实现，返回空视图
    @MainActor
    func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    /// 默认的状态栏前部视图实现，返回空视图
    @MainActor
    func addStatusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    /// 默认的状态栏中间视图实现，返回空视图
    @MainActor
    func addStatusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    /// 默认的状态栏后部视图实现，返回空视图
    @MainActor
    func addStatusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        nil
    }

    /// 默认的详情视图实现，返回空视图
    @MainActor
    func addDetailView(for tab: String) -> AnyView? {
        nil
    }

    /// 默认的列表视图实现，返回空
    func addListView(tab: String, project: Project?) -> AnyView? {
        nil
    }

    /// 默认的根视图包裹实现，返回 nil 表示不包裹
    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        nil
    }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        []
    }

    func viewWithProjectURL(_ view: AnyView, projectURL: URL?) -> AnyView {
        view
    }

    /// 提供根视图（接收 AnyView 参数的便捷方法）
    ///
    /// 内部调用 `addRootView`，将 AnyView 转换为 ViewBuilder。
    func provideRootView(_ content: AnyView) -> AnyView? {
        self.addRootView { content }
    }

    /// 包裹根视图（安全版本）
    ///
    /// 如果插件提供了根视图包装，则返回包装后的视图；
    /// 否则返回原始视图。
    ///
    /// - Parameter content: 要包裹的视图
    /// - Returns: 包裹后的视图
    func wrapRoot(_ content: AnyView) -> AnyView {
        if let wrapped = self.provideRootView(content) {
            return wrapped
        }
        return content
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
