import Foundation
import SwiftUI

// MARK: - App Lifecycle Events

/// 应用生命周期事件通知名称定义
extension Notification.Name {
    /// 应用准备就绪事件
    static let appReady = Notification.Name("appReady")
    
    /// 应用退出事件
    static let appExit = Notification.Name("appExit")
    
    /// 应用错误事件
    static let appError = Notification.Name("appError")
    
    /// 应用即将变为活跃状态
    static let appWillBecomeActive = Notification.Name("appWillBecomeActive")
    
    /// 应用即将失去活跃状态
    static let appWillResignActive = Notification.Name("appWillResignActive")
    
    /// 应用已变为活跃状态
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")

    /// 请求打开项目（通过 open-file、URL Scheme 或命令行触发）
    static let appOpenProject = Notification.Name("appOpenProject")
}

// MARK: - View Extensions for App Events

extension View {
    /// 监听应用准备就绪事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onAppReady(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appReady)) { _ in
            action()
        }
    }

    /// 监听应用退出事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onAppExit(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appExit)) { _ in
            action()
        }
    }

    /// 监听应用错误事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onAppError(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appError)) { _ in
            action()
        }
    }

    /// 监听应用即将变为活跃状态事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onApplicationWillBecomeActive(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive)) { _ in
            action()
        }
    }

    /// 监听应用即将失去活跃状态事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onApplicationWillResignActive(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appWillResignActive)) { _ in
            action()
        }
    }

    /// 监听应用已变为活跃状态事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onApplicationDidBecomeActive(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            action()
        }
    }

    /// 监听请求打开项目事件
    /// - Parameter action: 事件处理闭包，接收项目路径字符串
    /// - Returns: 修改后的视图
    func onAppOpenProject(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appOpenProject)) { notification in
            if let path = notification.userInfo?["path"] as? String {
                action(path)
            }
        }
    }
}

