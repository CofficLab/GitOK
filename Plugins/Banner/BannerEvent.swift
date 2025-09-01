import Foundation
import SwiftUI

/**
    Banner事件通知名称定义
    定义了所有Banner相关的系统通知事件，用于组件间的消息传递。
**/
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

/**
    View的Banner事件监听扩展
    提供便捷的Banner事件监听方法，简化视图中的事件处理代码。
    
    ## 使用示例
    ```swift
    SomeView()
        .onBannerAdded { notification in
            // 处理Banner添加事件
        }
        .onBannerChanged { notification in
            // 处理Banner改变事件
        }
    ```
**/
extension View {
    
    /**
        监听Banner列表变化事件
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerListChanged(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerListChanged), perform: action)
    }
    
    /**
        监听Banner添加事件
        
        ## 参数
        - `action`: 事件处理闭包，直接接收新添加的Banner ID
        
        ## 返回值
        返回添加了事件监听的View
        
        ## 示例
        ```swift
        SomeView()
            .onBannerAdded { newBannerId in
                // 直接获得新添加的Banner ID
                print("已添加Banner: \(newBannerId)")
            }
        ```
    */
    func onBannerAdded(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerAdded)) { notification in
            if let addedId = notification.userInfo?["id"] as? String {
                action(addedId)
            }
        }
    }
    
    /**
        监听Banner添加事件（原始版本）
        提供对原始Notification对象的访问，用于需要更多信息的场景
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerAddedNotification(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerAdded), perform: action)
    }
    
    /**
        监听Banner移除事件
        
        ## 参数
        - `action`: 事件处理闭包，直接接收被移除的Banner ID
        
        ## 返回值
        返回添加了事件监听的View
        
        ## 示例
        ```swift
        SomeView()
            .onBannerRemoved { removedId in
                // 直接获得被移除的Banner ID
                print("已移除Banner: \(removedId)")
            }
        ```
    */
    func onBannerRemoved(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerRemoved)) { notification in
            if let removedId = notification.userInfo?["id"] as? String {
                action(removedId)
            }
        }
    }
    
    /**
        监听Banner移除事件（原始版本）
        提供对原始Notification对象的访问，用于需要更多信息的场景
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerRemovedNotification(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerRemoved), perform: action)
    }
    
    /**
        监听Banner标题改变事件
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerTitleChanged(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerTitleChanged), perform: action)
    }
    
    /**
        监听Banner保存完成事件
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerDidSave(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerDidSave), perform: action)
    }
    
    /**
        监听Banner删除完成事件
        
        ## 参数
        - `action`: 事件处理闭包，直接接收被删除的Banner ID
        
        ## 返回值
        返回添加了事件监听的View
        
        ## 示例
        ```swift
        SomeView()
            .onBannerDidDelete { deletedId in
                // 直接获得被删除的Banner ID
                print("已删除Banner: \(deletedId)")
            }
        ```
    */
    func onBannerDidDelete(perform action: @escaping (String) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerDidDelete)) { notification in
            if let deletedId = notification.userInfo?["id"] as? String {
                action(deletedId)
            }
        }
    }
    
    /**
        监听Banner删除完成事件（原始版本）
        提供对原始Notification对象的访问，用于需要更多信息的场景
        
        ## 参数
        - `action`: 事件处理闭包，接收Notification对象
        
        ## 返回值
        返回添加了事件监听的View
    */
    func onBannerDidDeleteNotification(perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerDidDelete), perform: action)
    }
    
    /**
        监听Banner截图事件
        
        ## 参数
        - `action`: 事件处理闭包，直接接收截图请求
        
        ## 返回值
        返回添加了事件监听的View
        
        ## 示例
        ```swift
        SomeView()
            .onBannerSnapshot {
                // 处理截图请求
            }
        ```
    */
    func onBannerSnapshot(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .bannerSnapshot)) { _ in
            action()
        }
    }
}
