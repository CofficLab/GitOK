/// 自动化事件匹配工具。
///
/// SwiftUI modifier 本身较难做稳定单元测试，因此把“某个 request 是否匹配某类
/// mock action，并提取必要 payload”的逻辑集中到这里。View 扩展只负责订阅通知和
/// 调用 matcher，业务语义由这些纯函数保证。
public enum GitOKAutomationEventMatcher {
    /// 从“模拟选中 commit”请求中提取 commit hash。
    ///
    /// - Parameter request: 自动化请求。
    /// - Returns: 匹配成功时返回非空 commit hash，否则返回 `nil`。
    public static func commitHash(from request: GitOKAutomationRequest) -> String? {
        guard request.knownAction == .mockCommitSelected,
              let hash = request.payload[GitOKAutomationPayloadKey.hash],
              !hash.isEmpty else {
            return nil
        }
        return hash
    }

    /// 判断请求是否表示“模拟切回工作区”。
    public static func isWorkingTreeSelected(_ request: GitOKAutomationRequest) -> Bool {
        request.knownAction == .mockWorkingTreeSelected
    }

    /// 从“模拟选中文件”请求中提取文件路径。
    public static func filePath(from request: GitOKAutomationRequest) -> String? {
        path(from: request, matching: .mockFileSelected)
    }

    /// 从“模拟选中项目”请求中提取项目路径。
    public static func projectPath(from request: GitOKAutomationRequest) -> String? {
        path(from: request, matching: .mockProjectSelected)
    }

    private static func path(
        from request: GitOKAutomationRequest,
        matching action: GitOKAutomationAction
    ) -> String? {
        guard request.knownAction == action,
              let path = request.payload[GitOKAutomationPayloadKey.path],
              !path.isEmpty else {
            return nil
        }
        return path
    }
}
