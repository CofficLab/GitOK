import Foundation
import SwiftUI

// MARK: - Setting Events

/// 设置相关事件通知名称定义
extension Notification.Name {
    /// 打开设置视图事件
    static let openSettings = Notification.Name("openSettings")

    /// 打开插件设置事件（打开设置并定位到插件管理标签）
    static let openPluginSettings = Notification.Name("openPluginSettings")

    /// 打开仓库设置事件（打开设置并定位到仓库设置标签）
    static let openRepositorySettings = Notification.Name("openRepositorySettings")

    /// 打开Commit风格设置事件（打开设置并定位到Commit风格标签）
    static let openCommitStyleSettings = Notification.Name("openCommitStyleSettings")

    /// 关闭设置视图事件
    static let dismissSettings = Notification.Name("dismissSettings")
    
    /// 更新远程仓库事件
    static let didUpdateRemoteRepository = Notification.Name("didUpdateRemoteRepository")
    
    /// 保存Git用户配置事件
    static let didSaveGitUserConfig = Notification.Name("didSaveGitUserConfig")
    
    /// 更新Git用户配置事件
    static let didUpdateGitUserConfig = Notification.Name("didUpdateGitUserConfig")
}

// MARK: - View Extensions for Setting Events

extension View {
    /// 监听打开设置视图事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onOpenSettings(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            action()
        }
    }

    /// 监听打开插件设置事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onOpenPluginSettings(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .openPluginSettings)) { _ in
            action()
        }
    }

    /// 监听关闭设置视图事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onDismissSettings(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .dismissSettings)) { _ in
            action()
        }
    }

    /// 监听更新远程仓库事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onDidUpdateRemoteRepository(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .didUpdateRemoteRepository)) { _ in
            action()
        }
    }

    /// 监听保存Git用户配置事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onDidSaveGitUserConfig(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .didSaveGitUserConfig)) { _ in
            action()
        }
    }

    /// 监听更新Git用户配置事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onDidUpdateGitUserConfig(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .didUpdateGitUserConfig)) { _ in
            action()
        }
    }
}

