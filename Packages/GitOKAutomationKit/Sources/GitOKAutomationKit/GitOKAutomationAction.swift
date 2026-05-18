import Foundation

/// GitOK 自动化系统支持的语义化动作。
///
/// 这些动作是 HTTP API 和 SwiftUI View modifier 之间的稳定协议。
/// Package 只定义动作名称，不绑定 GitOK App 内部的 `ProjectVM`、commit model 或 file model。
public enum GitOKAutomationAction: String, CaseIterable, Sendable {
    /// 模拟用户在提交历史中选中某个 commit。
    ///
    /// Payload: `hash`
    case mockCommitSelected = "mock.commit.selected"

    /// 模拟用户切回工作区/当前未提交改动视图。
    case mockWorkingTreeSelected = "mock.working_tree.selected"

    /// 模拟用户选中某个文件。
    ///
    /// Payload: `path`
    case mockFileSelected = "mock.file.selected"

    /// 模拟用户选中某个项目。
    ///
    /// Payload: `path`
    case mockProjectSelected = "mock.project.selected"

    /// 请求 App 返回或记录当前状态快照。
    ///
    /// 第一版仅保留动作名，具体状态内容由 App 接入层定义。
    case stateSnapshot = "state.snapshot"
}

public extension Notification.Name {
    /// 自动化动作已被接收并分发给 App 侧消费者。
    static let gitOKAutomationActionReceived = Notification.Name("gitOKAutomationActionReceived")

    /// 自动化 HTTP 服务已经开始监听。
    static let gitOKAutomationServerDidStart = Notification.Name("gitOKAutomationServerDidStart")

    /// 自动化 HTTP 服务已经停止。
    static let gitOKAutomationServerDidStop = Notification.Name("gitOKAutomationServerDidStop")
}

/// 自动化通知 `userInfo` 中使用的字段名。
public enum GitOKAutomationUserInfoKey {
    /// 动作名称，值为 `String`。
    public static let action = "action"

    /// 动作参数，值为 `[String: String]`。
    public static let payload = "payload"

    /// 服务监听端口，值为 `Int`。
    public static let port = "port"
}

/// 自动化动作 payload 中常用的字段名。
public enum GitOKAutomationPayloadKey {
    /// Commit hash。
    public static let hash = "hash"

    /// 文件或项目的本地路径。
    public static let path = "path"
}

/// 一次自动化动作请求。
///
/// 该结构同时用于 HTTP 解析结果和 Notification 分发。Payload 统一降级为
/// `[String: String]`，避免 package 对 App 业务类型或复杂 JSON 结构产生依赖。
public struct GitOKAutomationRequest: Equatable, Sendable {
    /// 原始动作名称。
    public let action: String

    /// 字符串化后的动作参数。
    public let payload: [String: String]

    /// 创建自动化请求。
    /// - Parameters:
    ///   - action: 动作名称。
    ///   - payload: 动作参数，默认无参数。
    public init(action: String, payload: [String: String] = [:]) {
        self.action = action
        self.payload = payload
    }

    /// 将原始动作名称解析为已知动作。
    ///
    /// 当返回 `nil` 时，说明请求使用了当前 package 未定义的动作名。
    public var knownAction: GitOKAutomationAction? {
        GitOKAutomationAction(rawValue: action)
    }
}

/// 自动化 HTTP 响应的业务描述。
///
/// `GitOKAutomationHTTP` 会把它编码成完整 HTTP response bytes。
public struct GitOKAutomationResponse: Equatable, Sendable {
    /// HTTP 状态码。
    public let statusCode: Int

    /// JSON 中的状态字段，通常为 `ok` 或 `error`。
    public let status: String

    /// JSON 中的人类可读说明。
    public let message: String

    /// 创建自动化响应。
    public init(statusCode: Int, status: String, message: String) {
        self.statusCode = statusCode
        self.status = status
        self.message = message
    }

    /// 创建成功响应。
    public static func ok(_ message: String = "动作已分发") -> Self {
        Self(statusCode: 200, status: "ok", message: message)
    }

    /// 创建失败响应。
    public static func error(statusCode: Int = 400, _ message: String) -> Self {
        Self(statusCode: statusCode, status: "error", message: message)
    }
}

/// HTTP 请求解析结果。
///
/// 没有使用 Swift 标准库的 `Result`，因为失败分支需要携带可直接返回给客户端的
/// `GitOKAutomationResponse`，它不是 `Error`。
public enum GitOKAutomationParseResult: Equatable, Sendable {
    /// 请求解析成功。
    case success(GitOKAutomationRequest)

    /// 请求解析失败，可直接编码成 HTTP response。
    case failure(GitOKAutomationResponse)
}
