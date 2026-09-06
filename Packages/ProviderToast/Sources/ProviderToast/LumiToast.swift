import Foundation
import SwiftUI

// MARK: - Toast

/// 一条内核级 Toast 消息,用于向用户做瞬时提示。
///
/// 消费方通过 `kernel.toast?.show(...)` 发出;
/// 具体的展示(渲染、队列、自动消失策略)由实现 `ToastProviding` 的
/// 插件决定。该类型为纯值类型且 `Sendable`,可安全跨线程传递。
public struct LumiToast: Sendable, Equatable {
    /// 标题。
    public let title: String
    /// 可选副标题。
    public let detail: String?
    /// 展示风格(由实现映射为图标与色调)。
    public let style: LumiToastStyle
    /// 自定义展示时长(秒);`nil` 表示使用实现的默认时长。
    public let duration: TimeInterval?

    public init(
        title: String,
        detail: String? = nil,
        style: LumiToastStyle = .info,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.detail = detail
        self.style = style
        self.duration = duration
    }
}

/// 一条需要用户明确关闭的错误通知。
///
/// 与 `LumiToast` 的瞬时提示不同，错误通知不会自动消失，适合承载
/// divergent branches、认证失败等需要完整阅读或复制的底层错误信息。
public struct LumiErrorNotice: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let message: String

    public init(id: UUID = UUID(), title: String, message: String) {
        self.id = id
        self.title = title
        self.message = message
    }
}

/// Toast 的展示风格。
public enum LumiToastStyle: String, Sendable {
    case info
    case success
    case warning
    case error
}
