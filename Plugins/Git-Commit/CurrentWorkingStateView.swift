import MagicCore
import OSLog
import SwiftUI

/// 显示当前工作状态的视图组件
/// 显示未提交文件数量，并提供选择当前工作状态的功能
struct CurrentWorkingStateView: View, SuperLog {
    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 未提交文件数量
    @State private var changedFileCount = 0

    /// 是否正在刷新文件列表
    @State private var isRefreshing = false

    /// 是否正在进行远程同步刷新
    @State private var isRemoteSyncRefreshing = false

    /// 是否被选中（当前工作状态）
    private var isSelected: Bool {
        data.commit == nil
    }

    /// 是否启用详细日志输出
    static let verbose = false

    /// 日志标识符
    static let emoji = "🌳"

    /// 视图主体
    /// 显示当前工作状态信息和远程同步状态
    var body: some View {
        VStack(spacing: 0) {
            // 当前工作状态部分
            ZStack {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前状态")
                            .font(.system(size: 14, weight: .medium))

                        Text(isRefreshing ? "正在刷新..." : "(\(changedFileCount) 未提交)")
                            .font(.system(size: 11))
                    }

                    Spacer()
                }

                if isRefreshing || isRemoteSyncRefreshing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.white.opacity(0.2))

            // 远程同步状态部分
            RemoteSyncStatusView(isRefreshing: $isRemoteSyncRefreshing)
        }
        .background(
            isSelected
                ? Color.green.opacity(0.12)
                : Color(.controlBackgroundColor)
        )
        .onTapGesture(perform: onTap)
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectDidChange)
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onNotification(.appDidBecomeActive, onAppDidBecomeActive)
    }
}

// MARK: - Action

extension CurrentWorkingStateView {
    /// 加载未提交文件数量
    /// 获取当前项目的未跟踪文件数量并更新UI
    private func loadChangedFileCount() async {
        guard let project = data.project else {
            return
        }
        
        // 在状态栏显示刷新消息并显示 loading 提示
        await MainActor.run {
            data.activityStatus = "刷新文件列表…"
            isRefreshing = true
        }

        do {
            let count = try await project.untrackedFiles().count
            await MainActor.run {
                self.changedFileCount = count
                data.activityStatus = nil
                isRefreshing = false
            }
        } catch {
            await MainActor.run {
                data.activityStatus = nil
                isRefreshing = false
            }
            os_log(.error, "\(self.t)❌ Failed to load changed file count: \(error)")
        }
    }
}

// MARK: - Event

extension CurrentWorkingStateView {
    /// 视图出现时的事件处理：加载文件状态
    func onAppear() {
        Task {
            await self.loadChangedFileCount()
        }
    }

    /// 点击事件处理：选择当前工作状态并刷新文件列表
    func onTap() {
        data.commit = nil
        Task {
            await self.loadChangedFileCount()
        }
    }

    /// 项目提交完成事件处理：刷新文件列表
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        Task {
            await self.loadChangedFileCount()
        }
    }

    /// 项目改变事件处理：刷新文件列表
    func onProjectDidChange() {
        Task {
            await self.loadChangedFileCount()
        }
    }

    /// 应用激活事件处理：刷新文件列表
    func onAppDidBecomeActive(_ notification: Notification) {
        Task {
            await self.loadChangedFileCount()
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
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
