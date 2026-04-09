import Combine
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 显示当前工作状态的视图组件
/// 显示未提交文件数量、远程同步状态，并提供 git pull 功能
struct WorkingStateView: View, SuperLog {
    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// CommitList 是否正在刷新
    @Binding var isRefreshing: Bool

    // MARK: - 本地状态

    /// 未提交文件数量
    @State private var changedFileCount = 0

    /// 是否正在刷新文件列表
    @State private var isRefreshingFileList = false

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

    /// 定时检查远程状态的订阅
    @State private var timerCancellable: AnyCancellable? = nil

    /// 定时器间隔（秒）
    private let timerInterval: TimeInterval = 60

    /// 是否正在执行 pull 操作
    @State private var isPulling = false

    /// 是否正在执行 push 操作
    @State private var isPushing = false

    /// 是否显示凭据输入界面
    @State private var showCredentialInput = false

    /// 是否启用详细日志输出
    static let verbose = false

    /// 日志标识符
    static let emoji = "🌳"

    /// 初始化方法，提供默认的 binding 值
    init(isRefreshing: Binding<Bool> = .constant(false)) {
        _isRefreshing = isRefreshing
    }

    /// 视图主体
    var body: some View {
        HStack(spacing: 12) {
            // 图标和文本
            if changedFileCount == 0 {
                // 工作区干净
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            } else {
                // 有未提交文件
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                if changedFileCount == 0 {
                    // 工作区干净
                    Text("工作区干净", tableName: "GitCommit")
                        .font(.system(size: 14, weight: .medium))

                    if unpulledCount > 0 {
                        Text("远程有 \(unpulledCount) 个提交可拉取", tableName: "GitCommit")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("所有更改已提交", tableName: "GitCommit")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 有未提交文件
                    Text("当前状态", tableName: "GitCommit")
                        .font(.system(size: 14, weight: .medium))

                    Text("(\(changedFileCount)) 未提交", tableName: "GitCommit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 按钮显示逻辑
            if isRefreshing {
                // 刷新中，显示 loading 提示
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                    Text("刷新中", tableName: "GitCommit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            } else if changedFileCount == 0 {
                // 本地干净
                if unpulledCount > 0 {
                    // 远程有新提交，显示下载按钮
                    downloadButton
                }
                // 否则不显示按钮
            } else {
                // 有未提交文件
                if unpulledCount == 0 {
                    // 远程没有新提交，显示上传按钮
                    uploadButton
                }
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
        .onDisappear(perform: onDisappear)
        .onChange(of: vm.project, onProjectDidChange)
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onProjectDidPush(perform: onProjectDidPush)
        .onProjectDidPull(perform: onProjectDidPull)
        .onNotification(.appDidBecomeActive, onAppDidBecomeActive)
        .sheet(isPresented: $showCredentialInput) {
            CredentialInputView {
                // 凭据保存后，重新执行 push/pull
                if isPushing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        performPush()
                    }
                } else if isPulling {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        performPull()
                    }
                }
            }
        }
    }

    /// 下载按钮（执行 git pull）
    private var downloadButton: some View {
        AppButton(
            LocalizedStringKey(isPulling ? "拉取中..." : "拉取"),
            systemImage: isPulling ? nil : "arrow.down.circle.fill",
            style: .tonal,
            size: .small
        ) {
            performPull()
        }
        .disabled(isPulling)
        .help(String(localized: "点击执行 git pull 拉取远程提交", table: "GitCommit"))
    }

    /// 上传按钮（执行 git push）
    private var uploadButton: some View {
        AppButton(
            LocalizedStringKey(isPushing ? "推送中..." : "推送"),
            systemImage: isPushing ? nil : "arrow.up.circle.fill",
            style: .tonal,
            size: .small
        ) {
            performPush()
        }
        .disabled(isPushing)
        .help(String(localized: "点击执行 git push 推送本地提交", table: "GitCommit"))
    }
}

// MARK: - Actions

extension WorkingStateView {
    /// 加载未提交文件数量
    private func loadChangedFileCount() async {
        guard let project = vm.project else {
            return
        }

        await MainActor.run {
            data.activityStatus = String(localized: "刷新文件列表…", table: "GitCommit")
            isRefreshingFileList = true
        }

        do {
            let count = try await project.untrackedFiles().count
            await MainActor.run {
                self.changedFileCount = count
                data.activityStatus = nil
                isRefreshingFileList = false
            }
        } catch {
            await MainActor.run {
                data.activityStatus = nil
                isRefreshingFileList = false
            }
            os_log(.error, "\(self.t)❌ Failed to load changed file count: \(error)")
        }
    }

    /// 加载远程同步状态：获取未推送和未拉取的提交数量
    private func loadSyncStatus() {
        guard let project = vm.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)<\(project.path)>Loading sync status")
        }

        // 设置活动状态
        setStatus(String(localized: "检查远程状态…", table: "GitCommit"))

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
                // 使用 getUnPulledCount() 获取远程领先的提交数量
                unpulledCount = try project.getUnPulledCount()
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

                if Self.verbose {
                    os_log("\(self.t)✅ Sync status updated: unpushed=\(unpushedCount), unpulled=\(unpulledCount)")
                }
            }

            // 延迟清除状态，确保用户能看到提示（至少显示2秒）
            try? await Task.sleep(nanoseconds: 2000000000)
            self.setStatus(nil)
        }

        // 立即更新 loading 状态
        isSyncLoading = true
    }

    /// 设置活动状态
    /// - Parameter text: 状态文本，为 nil 时清除状态
    private func setStatus(_ text: String?) {
        Task { @MainActor in
            data.activityStatus = text
        }
    }

    /// 执行 git pull 操作拉取远程提交
    private func performPull() {
        guard let project = vm.project else {
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
        setStatus(String(localized: "拉取中…", table: "GitCommit"))

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
                case let .failure(error):
                    // 检查是否需要凭据
                    if self.isCredentialError(error) {
                        self.showCredentialInput = true
                    } else {
                        alert_error(error)
                    }
                }
            }

            // 清除状态日志
            self.setStatus(nil)
        }
    }

    /// 执行 git push 操作推送本地提交
    private func performPush() {
        guard let project = vm.project else {
            if Self.verbose {
                os_log("\(self.t)No project found")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)<\(project.path)>Performing git push")
        }

        // 立即更新 UI 状态
        isPushing = true

        // 设置状态日志
        setStatus("推送中…")

        // 使用 Task.detached 确保在后台执行
        Task.detached(priority: .userInitiated) {
            let result: Result<Void, Error>

            do {
                // 在后台线程执行耗时操作
                try project.push()
                result = .success(())
                await MainActor.run {
                    os_log("\(Self.t)✅ Git push succeeded")
                }
            } catch {
                result = .failure(error)
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git push failed: \(error)")
                }
            }

            // 在主线程处理结果和更新 UI
            await MainActor.run {
                self.isPushing = false

                switch result {
                case .success:
                    // 重新加载同步状态
                    self.loadSyncStatus()
                case let .failure(error):
                    // 检查是否需要凭据
                    if self.isCredentialError(error) {
                        self.showCredentialInput = true
                    } else {
                        alert_error(error)
                    }
                }
            }

            // 清除状态日志
            self.setStatus(nil)
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
            "forbidden",
        ]

        return authKeywords.contains { errorDescription.contains($0) }
    }
}

// MARK: - Event Handlers

extension WorkingStateView {
    /// 视图出现时的事件处理：加载状态并启动定时器
    func onAppear() {
        Task {
            await self.loadChangedFileCount()
        }
        loadSyncStatus()
        startRemoteStatusTimer()
    }

    /// 视图消失时的事件处理：停止定时器
    func onDisappear() {
        stopRemoteStatusTimer()
    }

    /// 启动定时器，定期检查远程状态
    private func startRemoteStatusTimer() {
        // 取消之前的定时器
        timerCancellable?.cancel()

        // 创建新的定时器
        timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                if Self.verbose {
                    os_log("\(self.t)⏰ Timer fired, checking remote status")
                }
                self.loadSyncStatus()
            }

        if Self.verbose {
            os_log("\(self.t)⏰ Started remote status timer (interval: \(timerInterval)s)")
        }
    }

    /// 停止定时器
    private func stopRemoteStatusTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        if Self.verbose {
            os_log("\(self.t)⏰ Stopped remote status timer")
        }
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
            try? await Task.sleep(nanoseconds: 500000000)
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
