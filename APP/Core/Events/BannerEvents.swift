import Foundation
import SwiftUI

// MARK: - Banner Events

/// Banner相关事件通知名称定义
extension Notification.Name {
    /// Banner列表发生变化事件
    static let bannerListChanged = Notification.Name("bannerListChanged")
    
    /// 新增Banner事件
    static let bannerAdded = Notification.Name("bannerAdded")
    
    /// 移除Banner事件
    static let bannerRemoved = Notification.Name("bannerRemoved")
    
    /// Banner标题改变事件
    static let bannerTitleChanged = Notification.Name("bannerTitleChanged")
    
    /// Banner保存完成事件
    static let bannerDidSave = Notification.Name("bannerDidSave")
    
    /// Banner删除完成事件
    static let bannerDidDelete = Notification.Name("bannerDidDelete")
    
    /// Banner截图事件
    static let bannerSnapshot = Notification.Name("bannerSnapshot")
}

// MARK: - View Extensions for Banner Events

extension View {
    /// 监听Banner列表变化事件
    /// - Parameter action: 事件处理闭包，接收Notification对象
    /// - Returns: 修改后的视图
    func onBannerListChanged(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerListChanged), perform: action)
    }
    
    /// 监听Banner添加事件
    /// - Parameter action: 事件处理闭包，直接接收新添加的Banner ID
    /// - Returns: 修改后的视图
    func onBannerAdded(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerAdded)) { notification in
            if let addedId = notification.userInfo?["id"] as? String {
                action(addedId)
            }
        }
    }
    
    /// 监听Banner添加事件（原始版本）
    /// - Parameter action: 事件处理闭包，接收Notification对象
    /// - Returns: 修改后的视图
    func onBannerAddedNotification(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerAdded), perform: action)
    }
    
    /// 监听Banner移除事件
    /// - Parameter action: 事件处理闭包，直接接收被移除的Banner ID
    /// - Returns: 修改后的视图
    func onBannerRemoved(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerRemoved)) { notification in
            if let removedId = notification.userInfo?["id"] as? String {
                action(removedId)
            }
        }
    }
    
    /// 监听Banner移除事件（原始版本）
    /// - Parameter action: 事件处理闭包，接收Notification对象
    /// - Returns: 修改后的视图
    func onBannerRemovedNotification(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerRemoved), perform: action)
    }
    
    /// 监听Banner标题改变事件
    /// - Parameter action: 事件处理闭包，接收Notification对象
    /// - Returns: 修改后的视图
    func onBannerTitleChanged(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerTitleChanged), perform: action)
    }
    
    /// 监听Banner保存完成事件
    /// - Parameter action: 事件处理闭包，直接接收更新后的Banner对象
    /// - Returns: 修改后的视图
    func onBannerDidSave(perform action: @escaping (BannerFile) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerDidSave)) { notification in
            if let updatedBanner = notification.object as? BannerFile {
                action(updatedBanner)
            }
        }
    }
    
    /// 监听Banner删除完成事件
    /// - Parameter action: 事件处理闭包，直接接收被删除的Banner ID
    /// - Returns: 修改后的视图
    func onBannerDidDelete(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerDidDelete)) { notification in
            if let deletedId = notification.userInfo?["id"] as? String {
                action(deletedId)
            }
        }
    }
    
    /// 监听Banner截图事件
    /// - Parameter action: 事件处理闭包
    /// - Returns: 修改后的视图
    func onBannerSnapshot(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerSnapshot)) { _ in
            action()
        }
    }
}

