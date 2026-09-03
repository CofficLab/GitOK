import KitGit
import LumiUI
import ProviderCommit
import SwiftUI

/// Commit 详情主内容视图。
///
/// 订阅 `CommitDetailProviding`：无选中 commit 时显示占位；
/// 有选中时展示 commit 信息头 + 文件列表。文件列表选中某文件时
/// 通过 Provider 写入 `selectedFile`，右侧的 git diff 插件（trailing pane）
/// 据此展示该文件的 diff——diff 渲染已从本视图拆分出去。
struct CommitDetailView: View {
    let detail: any CommitDetailProviding

    @StateObject private var observation: CommitDetailObservationModel

    init(detail: any CommitDetailProviding) {
        self.detail = detail
        _observation = StateObject(wrappedValue: CommitDetailObservationModel(detail: detail))
    }

    var body: some View {
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
                AppEmptyState(
                    icon: "doc.text.magnifyingglass",
                    title: "No Commit Selected",
                    description: "Select a commit from the commit list to see its changes."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
