import KitGit
import LumiUI
import ProviderCommit
import SwiftUI

/// Commit 详情主内容视图。
///
/// 订阅 `CommitDetailProviding`：无选中 commit 时显示占位；
/// 有选中时展示 commit 信息头 + （文件列表 | diff 详情）两栏，
/// 对齐旧版 GitDetail 布局（header + HSplitView）。
struct CommitDetailView: View {
    let detail: any CommitDetailProviding

    @StateObject private var observation: CommitDetailObservationModel
    @State private var selectedFilePath: String?
    @State private var lastHandledHash: String?

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
                    selectedFilePath: $selectedFilePath
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
            handleSelectionChange()
        }
        .onAppear {
            handleSelectionChange()
        }
    }

    /// 选中 commit 变化后重置文件选择（保持与当前 commit 同步）。
    private func handleSelectionChange() {
        guard let commit = detail.selectedCommit else { return }
        if commit.hash != lastHandledHash {
            lastHandledHash = commit.hash
            selectedFilePath = nil
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
