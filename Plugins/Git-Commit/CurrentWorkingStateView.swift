import MagicKit
import MagicAlert
import LibGit2Swift
import OSLog
import SwiftUI

/// 显示当前工作状态的视图组件
/// 显示未提交文件数量、远程同步状态，并提供 git pull 功能
struct CurrentWorkingStateView: View, SuperLog {
    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider
    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    // MARK: - 本地状态

    /// 未提交文件数量
    @State private var changedFileCount = 0

    /// 是否正在刷新文件列表
    @State private var isRefreshing = false

    /// 是否被选中（当前工作状态）
    private var isSelected: Bool {
        data.commit == nil
    }

    // MARK: - 远程同步状态

    /// 未推送的提交数量（本地领先远程）
    @State private var unpushedCount = 0

    /// 未拉取的提交数量（远程领先本地）
    @State private var unpulledCount = 0

    /// 是否正在加载同步状态
    @State private var isSyncLoading = false

    /// 下载按钮是否被鼠标悬停
    @State private var isDownloadButtonHovered = false

    /// 是否正在执行 pull 操作
    @State private var isPulling = false

    /// 是否显示凭据输入界面
    @State private var showCredentialInput = false

    /// 是否启用详细日志输出
    static let verbose = false

    /// 日志标识符
    static let emoji = "🌳"

    /// 视图主体
    var body: some View {
        // 只在本地没有未提交文件时显示
        if changedFileCount == 0 {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("工作区干净")
                        .font(.system(size: 14, weight: .medium))

                    if unpulledCount > 0 {
                        Text("远程有 \(unpulledCount) 个提交可拉取")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("所有更改已提交")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 只在远程有未拉取提交时显示下载按钮
                if unpulledCount > 0 {
                    downloadButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.1)
                    : Color(.controlBackgroundColor)
            )
            .onTapGesture(perform: onTap)
            .onAppear(perform: onAppear)
            .onChange(of: data.project, onProjectDidChange)
            .onProjectDidCommit(perform: onProjectDidCommit)
            .onProjectDidPush(perform: onProjectDidPush)
            .onProjectDidPull(perform: onProjectDidPull)
            .onNotification(.appDidBecomeActive, onAppDidBecomeActive)
            .sheet(isPresented: $showCredentialInput) {
                CredentialInputView {
                    // 凭据保存后，重新执行 pull
                    if isPulling {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            performPull()
                        }
                    }
                }
            }
        } else {
            // 本地有未提交文件，不显示任何内容
            EmptyView()
        }
    }

    /// 下载按钮（执行 git pull）
    private var downloadButton: some View {
        Button(action: performPull) {
            HStack(spacing: 4) {
                Image(systemName: isPulling ? "arrow.down.circle" : "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                    .rotationEffect(.degrees(isPulling ? 360 : 0))
                    .animation(isPulling ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isPulling)

                Text("拉取")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isDownloadButtonHovered ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPulling)
        .help("点击执行 git pull 拉取远程提交")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDownloadButtonHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pointingHand.pop()
            }
        }
    }
}

// MARK: - Actions

extension CurrentWorkingStateView {
    /// 加载未提交文件数量
    private func loadChangedFileCount() async {
        guard let project = data.project else {
            return
        }

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

    /// 加载远程同步状态：获取未推送和未拉取的提交数量
    private func loadSyncStatus() {
        guard let project = data.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)<\(project.path)>Loading sync status")
        }

        // 使用 Task.detached 确保在后台执行，不继承 actor 上下文
        Task.detached(priority: .userInitiated) {
            // 在后台线程执行耗时操作
            let unpushedCount: Int
            let unpulledCount: Int

            do {
                let unpushed = try await project.getUnPushedCommits()
                unpushedCount = unpushed.count
            } catch {
                unpushedCount = 0
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to load unpushed commits count: \(error)")
                }
            }

            do {
                let unpulled = try await project.getUnPulledCommits()
                unpulledCount = unpulled.count
            } catch {
                unpulledCount = 0
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to load unpulled commits count: \(error)")
                }
            }

            // 在主线程更新 UI
            await MainActor.run {
                self.unpushedCount = unpushedCount
                self.unpulledCount = unpulledCount
                self.isSyncLoading = false
            }
        }

        // 立即更新 loading 状态
        isSyncLoading = true
    }

    /// 设置活动状态日志
    /// - Parameter text: 状态文本，为 nil 时清除状态
    private func setStatus(_ text: String?) async {
        await MainActor.run {
            data.activityStatus = text
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
            os_log("\(self.t)<\(project.path)>Performing git pull")
        }

        // 立即更新 UI 状态
        isPulling = true

        // 设置状态日志
        Task { await setStatus("拉取中…") }

        // 使用 Task.detached 确保在后台执行
        Task.detached(priority: .userInitiated) {
            let result: Result<Void, Error>

            do {
                // 在后台线程执行耗时操作
                try project.pull()
                result = .success(())
                await MainActor.run {
                    os_log("\(Self.t)✅ Git pull succeeded")
                }
            } catch {
                result = .failure(error)
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git pull failed: \(error)")
                }
            }

            // 在主线程处理结果和更新 UI
            await MainActor.run {
                self.isPulling = false

                switch result {
                case .success:
                    // 重新加载同步状态
                    self.loadSyncStatus()
                case .failure(let error):
                    // 检查是否需要凭据
                    if self.isCredentialError(error) {
                        self.showCredentialInput = true
                    } else {
                        self.m.error(error)
                    }
                }
            }

            // 清除状态日志
            await setStatus(nil)
        }
    }

    /// 检查错误是否是认证错误
    private func isCredentialError(_ error: Error) -> Bool {
        // 检查是否是 LibGit2Error.authenticationError
        if let libGit2Error = error as? LibGit2Error {
            if case .authenticationError = libGit2Error {
                return true
            }
        }

        // 检查错误描述中是否包含认证相关的关键词
        let errorDescription = error.localizedDescription.lowercased()
        let authKeywords = [
            "authentication",
            "auth",
            "credential",
            "permission",
            "denied",
            "unauthorized",
            "401",
            "403",
            "forbidden"
        ]

        return authKeywords.contains { errorDescription.contains($0) }
    }
}

// MARK: - Event Handlers

extension CurrentWorkingStateView {
    /// 视图出现时的事件处理：加载状态
    func onAppear() {
        Task {
            await self.loadChangedFileCount()
        }
        loadSyncStatus()
    }

    /// 点击事件处理：选择当前工作状态并刷新文件列表
    func onTap() {
        data.commit = nil
        Task {
            await self.loadChangedFileCount()
        }
    }

    /// 项目提交完成事件处理：刷新状态
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        Task {
            await self.loadChangedFileCount()
        }
        loadSyncStatus()
    }

    /// 项目改变事件处理：刷新状态
    func onProjectDidChange() {
        Task {
            await self.loadChangedFileCount()
        }
        loadSyncStatus()
    }

    /// 项目 push 成功事件处理：刷新状态
    func onProjectDidPush(_ eventInfo: ProjectEventInfo) {
        loadSyncStatus()
    }

    /// 项目 pull 成功事件处理：刷新状态
    func onProjectDidPull(_ eventInfo: ProjectEventInfo) {
        loadSyncStatus()
    }

    /// 应用激活事件处理：延迟刷新，避免与其他组件同时刷新
    func onAppDidBecomeActive(_ notification: Notification) {
        Task {
            // 延迟 0.5 秒，让其他组件先完成刷新
            try? await Task.sleep(nanoseconds: 500_000_000)
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
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
