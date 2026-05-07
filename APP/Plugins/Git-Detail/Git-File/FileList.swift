import AppKit
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 显示 Git 仓库文件变更列表的视图组件
/// 支持显示暂存区文件或提交间的文件差异，并提供文件丢弃更改功能
struct FileList: View, SuperThread, SuperLog {
    nonisolated static let emoji = "📁"
    nonisolated static let verbose = false

    /// 环境对象
    @EnvironmentObject var app: AppVM
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 当前显示的文件列表
    @State var files: [GitDiffFile] = []

    /// 是否正在加载文件列表
    @State var isLoading = true

    /// 当前选中的文件
    @State var selection: GitDiffFile?

    /// 当前的刷新任务，用于取消之前的刷新操作
    @State private var refreshTask: Task<Void, Never>?
    /// 后台刷新工作任务
    @State private var refreshWorkerTask: Task<([GitDiffFile], String?), Error>?

    /// 是否显示丢弃单个文件更改的确认对话框
    @State private var showDiscardFileAlert = false

    /// 要丢弃更改的文件
    @State private var fileToDiscard: GitDiffFile?

    /// 是否显示丢弃所有更改的确认对话框
    @State private var showDiscardAllAlert = false

    /// 上次刷新时间，用于防抖控制
    @State private var lastRefreshTime: Date = Date.distantPast

    /// 丢弃所有按钮的 hover 状态
    @State private var discardButtonHovered = false

    /// 当前错误信息
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            fileInfoBar
            if let error = errorMessage {
                FileListErrorView(message: error) {
                    Task {
                        await self.refresh(reason: "RetryAfterError")
                    }
                }
            } else {
                fileListView
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: vm.project, onProjectChange)
        .onChange(of: data.commit, onCommitChange)
        .onChange(of: selection, onSelectionChange)
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
        .alert("确认丢弃所有更改", isPresented: $showDiscardAllAlert) {
            Button("取消", role: .cancel) { }
            Button("丢弃所有", role: .destructive) {
                discardAllChanges()
            }
        } message: {
            Text("确定要丢弃所有文件的更改吗？此操作不可撤销。")
        }
    }
}

// MARK: - View

extension FileList {
    /// 文件信息栏：显示文件数量和加载状态
    private var fileInfoBar: some View {
        HStack {
            if data.commit == nil && !files.isEmpty {
                Button(action: {
                    showDiscardAllAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12))
                        Text("丢弃所有更改")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(discardButtonHovered ? Color.red.opacity(0.15) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .foregroundColor(discardButtonHovered ? .white : .red)
                .help("丢弃所有文件的更改")
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        discardButtonHovered = hovering
                    }
                }
            }

            Spacer()

            if isLoading {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image.doc
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text("\(files.count) 个文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    /// 文件列表视图：显示可滚动的文件列表
    private var fileListView: some View {
        ScrollViewReader { scrollProxy in
            List(files, id: \.self, selection: $selection) {
                FileTile(
                    file: $0,
                    onDiscardChanges: data.commit == nil ? {
                        discardChanges(for: $0)
                    } : nil
                )
                .tag($0 as GitDiffFile?)
                .listRowInsets(.init()) // 移除 List 的默认内边距
            }
            .listStyle(.plain) // 使用 plain 样式移除额外的 padding
            .onChange(of: files, {
                withAnimation {
                    // 在主线程中调用 scrollTo 方法
                    scrollProxy.scrollTo(vm.file, anchor: .top)
                }
            })
        }
    }
}

// MARK: - Action

extension FileList {
    /// 丢弃指定文件的更改
    /// - Parameter file: 要丢弃更改的文件
    func discardChanges(for file: GitDiffFile) {
        guard let project = vm.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                // 在后台执行耗时操作
                try project.discardFileChanges(file.file)

                // 在主线程更新 UI
                await MainActor.run {
                    alert_info("已丢弃文件更改: \(file.file)")
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardChanges")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ 丢弃文件更改失败: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    /// 丢弃所有文件的更改
    func discardAllChanges() {
        guard let project = vm.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                // 在后台执行耗时操作
                try project.discardAllChanges()

                // 在主线程更新 UI
                await MainActor.run {
                    alert_info("已丢弃所有文件的更改")
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardAllChanges")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ 丢弃所有更改失败: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    /// 刷新文件列表，支持防抖控制
    /// - Parameter reason: 刷新原因，用于日志记录
    func refresh(reason: String) async {
        let now = Date()

        // 防抖：500ms 内的重复刷新请求会被忽略
        guard now.timeIntervalSince(lastRefreshTime) > 0.5 else {
            if Self.verbose {
                os_log("\(self.t)🚫 Refresh skipped (debounced): \(reason)")
            }
            return
        }

        lastRefreshTime = now

        // 取消之前的任务
        refreshTask?.cancel()
        refreshWorkerTask?.cancel()

        // 创建新的任务
        refreshTask = Task {
            await performRefresh(reason: reason)
        }

        // 等待任务完成
        await refreshTask?.value
    }

    /// 执行文件列表刷新操作
    /// - Parameter reason: 刷新原因，用于日志记录
    private func performRefresh(reason: String) async {
        // 先在主线程更新加载状态
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil  // 清除之前的错误
        }

        guard let project = vm.project else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }

        // 捕获必要的数据，避免在后台任务中访问 MainActor
        let currentCommitHash = data.commit?.hash

        do {
            // 创建后台任务
            let worker = Task.detached(priority: .userInitiated) {
                if Self.verbose {
                    os_log("\(Self.t)🍋 Refreshing \(reason)")
                }

                // 检查任务是否被取消
                try Task.checkCancellation()

                let newFiles: [GitDiffFile]
                if let hash = currentCommitHash {
                    newFiles = try await project.changedFilesDetail(in: hash)
                } else {
                    newFiles = try await project.untrackedFiles()
                }

                // 再次检查任务是否被取消
                try Task.checkCancellation()

                return (newFiles, currentCommitHash)
            }
            refreshWorkerTask = worker
            let (newFiles, selectedCommitHash) = try await worker.value

            // 在主线程更新 UI
            await MainActor.run {
                // 确保在刷新过程中 commit 没有变化
                guard selectedCommitHash == self.data.commit?.hash else {
                    if Self.verbose {
                        os_log("\(self.t)🔄 Commit changed during refresh, skipping UI update")
                    }
                    return
                }

                self.files = newFiles
                self.selection = newFiles.first
                self.vm.setFile(self.selection)
                self.isLoading = false
            }
        } catch is CancellationError {
            // 任务被取消，在主线程更新状态
            await MainActor.run {
                self.isLoading = false
            }
            if Self.verbose {
                os_log("\(self.t)🐜 Refresh cancelled: \(reason)")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                let gitDetailError = GitDetailError.from(error, context: "refreshFileList")
                self.errorMessage = gitDetailError.localizedDescription
                os_log(.error, "\(Self.t)❌ 刷新文件列表失败: \(gitDetailError.localizedDescription)")
            }
        }
    }
}

// MARK: - Event Handler

extension FileList {
    /// 视图出现时的事件处理
    func onAppear() {
        Task {
            await self.refresh(reason: "OnAppear")
        }
    }

    /// 项目变更时的事件处理
    func onProjectChange() {
        Task {
            await self.refresh(reason: "OnProjectChanged")
        }
    }

    /// 提交变更时的事件处理
    func onCommitChange() {
        Task {
            await self.refresh(reason: "OnCommitChanged")
        }
    }

    /// 选中文件变更时的事件处理
    func onSelectionChange() {
        self.vm.setFile(self.selection)
    }

    /// 项目提交完成时的事件处理
    /// - Parameter eventInfo: 项目事件信息
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        Task {
            await self.refresh(reason: "OnProjectDidCommit")
        }
    }

    /// 应用即将变为活跃状态时的事件处理
    func onAppWillBecomeActive() {
        Task {
            // 绕过防抖机制，直接执行刷新（应用激活是关键事件，需要立即响应）
            await self.performRefresh(reason: "OnAppWillBecomeActive")
        }
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
