import Foundation

/// SwiftUI modifier 使用的动作过滤与回调适配器。
///
/// 该类型不暴露给 package 使用者，只把视图层里的语义判断抽成可测试的纯逻辑。
/// 对外 API 仍然只保留 `onMockCommitSelected`、`onMockWorkingTreeSelected`、
/// `onMockFileSelected` 和 `onMockProjectSelected`。
enum GitOKAutomationViewActionHandlers {
    /// 从 NotificationCenter 通知中还原自动化请求。
    ///
    /// - Parameter notification: 自动化服务发出的动作通知。
    /// - Returns: 通知包含有效 action 时返回请求，否则返回 nil。
    static func request(from notification: Notification) -> GitOKAutomationRequest? {
        guard let userInfo = notification.userInfo,
              let action = userInfo[GitOKAutomationUserInfoKey.action] as? String else {
            return nil
        }
        let payload = userInfo[GitOKAutomationUserInfoKey.payload] as? [String: String] ?? [:]
        return GitOKAutomationRequest(action: action, payload: payload)
    }

    /// 创建“选中 commit”动作处理器。
    static func commitSelected(
        _ handler: @escaping (_ commitHash: String) -> Void
    ) -> (_ request: GitOKAutomationRequest) -> Void {
        { request in
            guard let hash = GitOKAutomationEventMatcher.commitHash(from: request) else {
                return
            }
            handler(hash)
        }
    }

    /// 创建“切回工作区”动作处理器。
    static func workingTreeSelected(
        _ handler: @escaping () -> Void
    ) -> (_ request: GitOKAutomationRequest) -> Void {
        { request in
            guard GitOKAutomationEventMatcher.isWorkingTreeSelected(request) else {
                return
            }
            handler()
        }
    }

    /// 创建“选中文件”动作处理器。
    static func fileSelected(
        _ handler: @escaping (_ path: String) -> Void
    ) -> (_ request: GitOKAutomationRequest) -> Void {
        { request in
            guard let path = GitOKAutomationEventMatcher.filePath(from: request) else {
                return
            }
            handler(path)
        }
    }

    /// 创建“选中项目”动作处理器。
    static func projectSelected(
        _ handler: @escaping (_ path: String) -> Void
    ) -> (_ request: GitOKAutomationRequest) -> Void {
        { request in
            guard let path = GitOKAutomationEventMatcher.projectPath(from: request) else {
                return
            }
            handler(path)
        }
    }
}
