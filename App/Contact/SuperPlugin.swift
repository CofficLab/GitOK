import SwiftUI

/// `SuperPlugin` 是 GitOK 应用的插件系统核心协议。
/// 所有插件必须实现此协议以便集成到应用程序中。
/// 
/// 该协议定义了插件的基本属性和行为，包括：
/// - 插件的标识和显示信息
/// - 插件在不同界面区域的视图渲染方法
/// - 插件的生命周期管理方法
protocol SuperPlugin {
    /// 插件的唯一标签，用于标识和区分不同的插件
    var label: String { get }
    
    /// 插件的图标名称，用于在界面上显示
    var icon: String { get }
    
    /// 指示插件是否作为主界面的标签页显示
    var isTab: Bool { get }
    
    /// 返回插件的数据库视图
    /// - Returns: 包装在 AnyView 中的数据库相关视图
    func addDBView() -> AnyView
    
    /// 返回插件的列表视图
    /// - Returns: 包装在 AnyView 中的列表视图
    func addListView() -> AnyView
    
    /// 返回插件的详情视图
    /// - Returns: 包装在 AnyView 中的详情视图
    func addDetailView() -> AnyView
    
    /// 返回插件在工具栏前部区域的视图
    /// - Returns: 包装在 AnyView 中的工具栏前部视图
    func addToolBarLeadingView() -> AnyView
    
    /// 返回插件在工具栏后部区域的视图
    /// - Returns: 包装在 AnyView 中的工具栏后部视图
    func addToolBarTrailingView() -> AnyView
    
    /// 返回插件在状态栏前部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏前部视图
    func addStatusBarLeadingView() -> AnyView
    
    /// 返回插件在状态栏后部区域的视图
    /// - Returns: 包装在 AnyView 中的状态栏后部视图
    func addStatusBarTrailingView() -> AnyView
    
    /// 插件初始化时调用
    /// - 在插件首次加载时执行必要的设置和初始化操作
    func onInit() -> Void
    
    /// 插件视图出现时调用
    /// - 当插件的视图被添加到视图层次结构中时执行操作
    func onAppear() -> Void
    
    /// 插件视图消失时调用
    /// - 当插件的视图从视图层次结构中移除时执行清理操作
    func onDisappear() -> Void
    
    /// 插件播放功能启动时调用
    /// - 用于处理插件的播放或动画相关功能
    func onPlay() -> Void
    
    /// 插件播放状态更新时调用
    /// - 用于响应播放状态的变化
    func onPlayStateUpdate() -> Void
    
    /// 插件播放资源更新时调用
    /// - 用于响应播放资源的变化
    func onPlayAssetUpdate() -> Void
}

/// SuperPlugin 协议的默认实现
/// 提供了一些方法的空实现，使插件开发者只需实现他们关心的方法
extension SuperPlugin {
    /// 默认的工具栏前部视图实现，返回空视图
    func addToolBarLeadingView() -> AnyView {
        AnyView(EmptyView())
    }
    
    /// 默认的工具栏后部视图实现，返回空视图
    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }
    
    /// 默认的状态栏前部视图实现，返回空视图
    func addStatusBarLeadingView() -> AnyView {
        AnyView(EmptyView())
    }

    /// 默认的状态栏后部视图实现，返回空视图
    func addStatusBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }

    /// 默认的详情视图实现，返回空视图
    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }
}
