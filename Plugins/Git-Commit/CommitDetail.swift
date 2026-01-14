import MagicKit
import MagicUI
import SwiftUI

/// 展示 Commit 详细信息的视图组件
/// 显示提交信息和相关的文件变更详情
struct CommitDetail: View, SuperEvent, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：数据提供者
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

    /// 背景视图
    private var background: some View {
        MagicBackground.orange.opacity(0.15)
    }
}

// MARK: - Event Handler

extension CommitDetail {
    /// 应用即将变为活跃状态的事件处理
    /// - Parameter notification: 通知对象
    func onAppWillBecomeActive(_ notification: Notification) {
    }

    /// 项目变更事件处理
    func onProjectChanged() {
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
