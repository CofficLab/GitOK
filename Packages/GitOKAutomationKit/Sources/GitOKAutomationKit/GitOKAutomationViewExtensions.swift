import SwiftUI

public extension View {
    /// 监听“模拟选中 commit”动作。
    ///
    /// HTTP 示例：
    /// `{ "action": "mock.commit.selected", "payload": { "hash": "abc123" } }`
    ///
    /// - Parameter handler: 传入 commit hash，由 App 侧负责解析并更新业务状态。
    func onMockCommitSelected(
        perform handler: @escaping (_ commitHash: String) -> Void
    ) -> some View {
        onGitOKAutomationAction(
            perform: GitOKAutomationViewActionHandlers.commitSelected(handler)
        )
    }

    /// 监听“模拟切回工作区”动作。
    ///
    /// 视图可在回调中清空 commit 选择，恢复工作区文件列表。
    func onMockWorkingTreeSelected(
        perform handler: @escaping () -> Void
    ) -> some View {
        onGitOKAutomationAction(
            perform: GitOKAutomationViewActionHandlers.workingTreeSelected(handler)
        )
    }

    /// 监听“模拟选中文件”动作。
    ///
    /// HTTP 示例：
    /// `{ "action": "mock.file.selected", "payload": { "path": "APP/App.swift" } }`
    ///
    /// - Parameter handler: 传入文件路径，由 App 侧决定路径语义是相对路径还是绝对路径。
    func onMockFileSelected(
        perform handler: @escaping (_ path: String) -> Void
    ) -> some View {
        onGitOKAutomationAction(
            perform: GitOKAutomationViewActionHandlers.fileSelected(handler)
        )
    }

    /// 监听“模拟选中项目”动作。
    ///
    /// HTTP 示例：
    /// `{ "action": "mock.project.selected", "payload": { "path": "/path/to/repo" } }`
    ///
    /// - Parameter handler: 传入项目本地路径，由 App 侧负责查找或打开项目。
    func onMockProjectSelected(
        perform handler: @escaping (_ path: String) -> Void
    ) -> some View {
        onGitOKAutomationAction(
            perform: GitOKAutomationViewActionHandlers.projectSelected(handler)
        )
    }
}

private extension View {
    /// 监听所有 GitOK 自动化动作。
    ///
    /// 这是 package 内部的底层订阅工具。对外只暴露语义化 modifier，避免 App 侧绕过
    /// 白名单语义直接处理任意 action。
    func onGitOKAutomationAction(
        perform handler: @escaping (_ request: GitOKAutomationRequest) -> Void
    ) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .gitOKAutomationActionReceived)) { notification in
            guard let request = GitOKAutomationViewActionHandlers.request(from: notification) else {
                return
            }
            handler(request)
        }
    }
}
