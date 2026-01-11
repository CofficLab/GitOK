import MagicKit
import MagicAlert
import OSLog
import SwiftUI

/// 显示远程仓库同步状态的视图组件
/// 显示本地领先远程和远程领先本地的提交数量，并提供手动刷新功能
struct RemoteSyncStatusView: View, SuperLog {
    /// 绑定到外部的刷新状态
    @Binding var isRefreshing: Bool
    /// 是否启用详细日志输出
    static let verbose = false

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider
    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    /// 未推送的提交数量（本地领先远程）
    @State private var unpushedCount = 0

    /// 未拉取的提交数量（远程领先本地）
    @State private var unpulledCount = 0

    /// 是否正在加载同步状态
    @State private var isLoading = false

    /// 刷新按钮是否被鼠标悬停
    @State private var isRefreshButtonHovered = false

    /// 未拉取按钮是否被鼠标悬停
    @State private var isUnpulledIndicatorHovered = false

    /// 未推送按钮是否被鼠标悬停
    @State private var isUnpushedIndicatorHovered = false

    /// 是否正在执行 pull 操作
    @State private var isPulling = false

    /// 是否正在执行 push 操作
    @State private var isPushing = false


    /// 是否有需要显示的同步状态
    private var hasSyncStatus: Bool {
        unpushedCount > 0 || unpulledCount > 0
    }

    /// 日志标识符
    static let emoji = "🔄"

    var body: some View {
        VStack(spacing: 0) {
            if hasSyncStatus {
                HStack(spacing: 12) {
                    if unpushedCount > 0 {
                        unpushedIndicator
                    }

                    if unpulledCount > 0 {
                        unpulledIndicator
                    }

                    Spacer()

                    refreshButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()
                    .background(Color.white.opacity(0.2))
            }

        }
        .onAppear(perform: onAppear)
        .onChange(of: data.project) { _, _ in
            onProjectChange()
        }
    }
}

// MARK: - View

extension RemoteSyncStatusView {
    /// 同步状态指示器容器：显示未推送和未拉取的提交数量
    private var syncStatusIndicators: some View {
        HStack(spacing: 4) {
            if unpushedCount > 0 {
                unpushedIndicator
            }

            if unpulledCount > 0 {
                unpulledIndicator
            }
        }
    }

    /// 未推送提交指示器：橙色向上箭头 + 数量（可点击执行 push）
    private var unpushedIndicator: some View {
        Button(action: performPush) {
            HStack(spacing: 2) {
                Image(systemName: isPushing ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(isPushing ? 360 : 0))
                    .animation(isPushing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isPushing)

                Text("\(unpushedCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            }
            .padding(4)
            .background(isUnpushedIndicatorHovered ? Color.orange.opacity(0.2) : Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPushing)
        .help("点击执行 git push 推送本地提交")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isUnpushedIndicatorHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pointingHand.pop()
            }
        }
    }

    /// 未拉取提交指示器：蓝色向下箭头 + 数量（可点击执行 pull）
    private var unpulledIndicator: some View {
        Button(action: performPull) {
            HStack(spacing: 2) {
                Image(systemName: isPulling ? "arrow.down.circle" : "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(isPulling ? 360 : 0))
                    .animation(isPulling ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isPulling)

                Text("\(unpulledCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(4)
            .background(isUnpulledIndicatorHovered ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPulling)
        .help("点击执行 git pull 拉取远程提交")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isUnpulledIndicatorHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pointingHand.pop()
            }
        }
    }

    /// 刷新按钮：点击时重新加载同步状态，支持旋转动画
    private var refreshButton: some View {
        Button(action: loadSyncStatus) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                .padding(4)
                .background(isRefreshButtonHovered ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .help("刷新同步状态")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isRefreshButtonHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pointingHand.pop()
            }
        }
    }
}

// MARK: - Action

extension RemoteSyncStatusView {
    /// 加载同步状态：获取未推送和未拉取的提交数量
    private func loadSyncStatus() {
        guard let project = data.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)Loading sync status for project: \(project.path)")
        }

        Task {
            await MainActor.run {
                isLoading = true
                isRefreshing = true
            }

            do {
                let unpushed = try project.getUnPushedCommits()
                await MainActor.run {
                    self.unpushedCount = unpushed.count
                }
            } catch {
                await MainActor.run {
                    self.unpushedCount = 0
                    os_log(.error, "\(self.t)❌ Failed to load unpushed commits count: \(error)")
                }
            }

            do {
                let unpulled = try project.getUnPulledCommits()
                await MainActor.run {
                    self.unpulledCount = unpulled.count
                    isLoading = false
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.unpulledCount = 0
                    isLoading = false
                    isRefreshing = false
                    os_log(.error, "\(self.t)❌ Failed to load unpulled commits count: \(error)")
                }
            }
        }
    }

    /// 执行 git pull 操作拉取远程提交
    private func performPull() {
        guard let project = data.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)Performing git pull for project: \(project.path)")
        }

        Task {
            await MainActor.run {
                isPulling = true
                isRefreshing = true
            }

            do {
                try project.pull()
                await MainActor.run {
                    os_log("\(self.t)✅ Git pull succeeded")
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "\(self.t)❌ Git pull failed: \(error)")
                    m.error(error)
                }
            }

            // 重新加载同步状态
            loadSyncStatus()

            await MainActor.run {
                isPulling = false
                isRefreshing = false
            }
        }
    }

    /// 执行 git push 操作推送本地提交
    private func performPush() {
        guard let project = data.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)Performing git push for project: \(project.path)")
        }

        Task {
            await MainActor.run {
                isPushing = true
                isRefreshing = true
            }

            do {
                try project.push()
                await MainActor.run {
                    os_log("\(self.t)✅ Git push succeeded")
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "\(self.t)❌ Git push failed: \(error)")
                    m.error(error)
                }
            }

            // 重新加载同步状态
            loadSyncStatus()

            await MainActor.run {
                isPushing = false
                isRefreshing = false
            }
        }
    }
}

// MARK: - Event

extension RemoteSyncStatusView {
    /// 视图出现时的事件处理：加载同步状态
    func onAppear() {
        if Self.verbose {
            os_log("\(self.t)View appeared, calling loadSyncStatus")
        }
        loadSyncStatus()
    }

    /// 项目改变时的事件处理：重新加载同步状态
    func onProjectChange() {
        if Self.verbose {
            os_log("\(self.t)Project changed, calling loadSyncStatus")
        }
        loadSyncStatus()
    }
}

// MARK: - Preview

#Preview("App-Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
