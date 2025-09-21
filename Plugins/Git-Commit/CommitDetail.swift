import MagicCore
import MagicBackground
import SwiftUI

/**
 * 展示 Commit 详细信息的视图组件
 */
struct CommitDetail: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let commit = data.commit {
                    CommitInfoView(commit: commit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HSplitView {
                FileList()
                    .frame(idealWidth: 200)
                    .frame(minWidth: 200, maxWidth: 300)
                    .layoutPriority(1)

                FileDetail()
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .background(background)
        .onChange(of: data.project) { self.onProjectChanged() }
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
    }

    private var background: some View {
        MagicBackground.orange.opacity(0.15)
    }
}

// MARK: - Event

extension CommitDetail {
    func onAppWillBecomeActive(_ notification: Notification) {
    }

    func onProjectChanged() {
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
