import KitGit
import LumiUI
import PluginCommitForm
import ProviderCommit
import ProviderCommitForm
import ProviderProjects
import SwiftUI

/// Commit 详情主内容视图。
///
/// 顶部嵌入提交表单（有 `CommitFormProviding` 时，对齐旧版 header 常驻表单）；
/// 下方订阅 `CommitDetailProviding`：无选中 commit 时显示占位；
/// 有选中时展示 commit 信息头 + 文件列表。文件列表选中某文件时
/// 通过 Provider 写入 `selectedFile`，右侧的 git diff 插件（trailing pane）
/// 据此展示该文件的 diff——diff 渲染已从本视图拆分出去。
struct CommitDetailView: View {
    let detail: any CommitDetailProviding
    let projects: any ProjectProviding
    let form: (any CommitFormProviding)?

    @StateObject private var observation: CommitDetailObservationModel

    init(
        detail: any CommitDetailProviding,
        projects: any ProjectProviding,
        form: (any CommitFormProviding)?
    ) {
        self.detail = detail
        self.projects = projects
        self.form = form
        _observation = StateObject(wrappedValue: CommitDetailObservationModel(detail: detail))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 提交表单常驻详情区顶部（对齐旧版 GitDetailContentLayout header）。
            if let form {
                CommitFormView(projects: projects, form: form)
                AppDivider()
            }

            Group {
                if let commit = detail.selectedCommit,
                   let projectURL = detail.selectedProjectURL {
                    CommitDetailLayout(
                        commit: commit,
                        projectURL: projectURL,
                        selectedFile: detail.selectedFile,
                        onSelectFile: { detail.selectFile($0) }
                    )
                } else {
                    // 无选中 commit 时展示工作区变动文件列表（用户点击工作区状态条触发）。
                    WorktreeChangesView(projects: projects, detail: detail)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(observation.$revision) { _ in
            // Provider 状态变化时重算 body，读取最新的 selectedCommit / selectedFile。
        }
    }
}

/// 观察模型：订阅 Provider 的观察者事件，转成 @Published revision。
@MainActor
final class CommitDetailObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitDetailObserverHandle)?

    init(detail: any CommitDetailProviding) {
        handle = detail.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
