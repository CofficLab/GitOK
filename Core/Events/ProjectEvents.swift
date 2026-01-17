import Foundation
import SwiftUI

// MARK: - Project Event Info

/// 项目事件信息结构
struct ProjectEventInfo {
    let project: Project
    let operation: String
    let success: Bool
    let error: Error?
    let additionalInfo: [String: Any]?

    init(project: Project, operation: String, success: Bool = true, error: Error? = nil, additionalInfo: [String: Any]? = nil) {
        self.project = project
        self.operation = operation
        self.success = success
        self.error = error
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Project Events

/// 项目相关事件通知名称定义
extension Notification.Name {
    /// 项目添加文件事件
    static let projectDidAddFiles = Notification.Name("projectDidAddFiles")
    
    /// 项目提交事件
    static let projectDidCommit = Notification.Name("projectDidCommit")
    
    /// 项目推送事件
    static let projectDidPush = Notification.Name("projectDidPush")
    
    /// 项目拉取事件
    static let projectDidPull = Notification.Name("projectDidPull")
    
    /// 项目合并事件
    static let projectDidMerge = Notification.Name("projectDidMerge")
    
    /// 项目同步事件
    static let projectDidSync = Notification.Name("projectDidSync")
    
    /// 项目切换分支事件
    static let projectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    
    /// 项目更新用户信息事件
    static let projectDidUpdateUserInfo = Notification.Name("projectDidUpdateUserInfo")
    
    /// 项目操作失败事件
    static let projectOperationDidFail = Notification.Name("projectOperationDidFail")
}

// MARK: - View Extensions for Project Events

extension View {
    /// 监听项目添加文件事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidAddFiles(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidAddFiles)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目提交事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidCommit(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidCommit)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目推送事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidPush(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidPush)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目拉取事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidPull(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidPull)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目合并事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidMerge(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidMerge)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目同步事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidSync(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidSync)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目切换分支事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidChangeBranch(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidChangeBranch)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目更新用户信息事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectDidUpdateUserInfo(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidUpdateUserInfo)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    /// 监听项目操作失败事件
    /// - Parameter action: 事件处理闭包，接收 ProjectEventInfo
    /// - Returns: 修改后的视图
    func onProjectOperationDidFail(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectOperationDidFail)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }
}

