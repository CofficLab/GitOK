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

    /// 插件注册顺序，数字越小越先注册
    static var order: Int { get }

    /// 插件显示名称
    static var displayName: String { get }

    /// 插件描述
    static var description: String { get }

    /// 插件图标名称
    static var iconName: String { get }

    /// 插件是否可配置（是否在设置中显示）
    static var isConfigurable: Bool { get }

    /// 插件默认启用状态，仅在用户未配置时生效
    /// 如果用户配置过，以用户配置为准
    static var defaultEnabled: Bool { get }

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
    func addDetailView(for tab: String) -> AnyView?

    /// 返回插件在工具栏前部区域的视图
    /// - Returns: 包装在 AnyView 中的工具栏前部视图
    func addToolBarLeadingView() -> AnyView?

    /// 返回插件在工具栏后部区域的视图
    /// - Returns: 包装在 AnyView 中的工具栏后部视图
    func addToolBarTrailingView() -> AnyView?

    /// 返回插件在状态栏前部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏前部视图
    func addStatusBarLeadingView() -> AnyView?

    /// 返回插件在状态栏中间区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏中间视图
    func addStatusBarCenterView() -> AnyView?

    /// 返回插件在状态栏后部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏后部视图
    func addStatusBarTrailingView() -> AnyView?
}

/// SuperPlugin 协议的默认实现
/// 提供了一些方法的空实现，使插件开发者只需实现他们关心的方法
extension SuperPlugin {
    /// 默认的标签项实现，返回 nil 表示不提供标签页
    func addTabItem() -> String? { nil }

    /// 默认的实例标签实现，使用反射获取类名
    var instanceLabel: String {
        let typeName = String(describing: type(of: self))
        // 移除模块前缀（例如 "GitOK."）
        if let dotIndex = typeName.lastIndex(of: ".") {
            return String(typeName[typeName.index(after: dotIndex)...])
        }
        return typeName
    }

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

    static var isConfigurable: Bool { true }

    /// 默认的启用状态实现，默认为启用
    static var defaultEnabled: Bool { true }

    /// 默认的工具栏前部视图实现，返回空视图
    func addToolBarLeadingView() -> AnyView? {
        nil
    }

    /// 默认的工具栏后部视图实现，返回空视图
    func addToolBarTrailingView() -> AnyView? {
        nil
    }

    /// 默认的状态栏前部视图实现，返回空视图
    func addStatusBarLeadingView() -> AnyView? {
        nil
    }

    /// 默认的状态栏中间视图实现，返回空视图
    func addStatusBarCenterView() -> AnyView? {
        nil
    }

    /// 默认的状态栏后部视图实现，返回空视图
    func addStatusBarTrailingView() -> AnyView? {
        nil
    }

    /// 默认的详情视图实现，返回空视图
    func addDetailView(for tab: String) -> AnyView? {
        nil
    }

    /// 默认的列表视图实现，返回空
    func addListView(tab: String, project: Project?) -> AnyView? {
        nil
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
