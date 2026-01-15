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

    /// 环境对象：应用提供者
    @EnvironmentObject var app: AppProvider

    /// 环境对象：消息提供者，用于显示提示信息
    @EnvironmentObject var m: MagicMessageProvider

    /// 环境对象：数据提供者，包含项目和提交信息
    @EnvironmentObject var data: DataProvider

    /// 当前显示的文件列表
    @State var files: [GitDiffFile] = []

    /// 是否正在加载文件列表
    @State var isLoading = true

    /// 当前选中的文件
    @State var selection: GitDiffFile?

    /// 当前的刷新任务，用于取消之前的刷新操作
    @State private var refreshTask: Task<Void, Never>?

    /// 是否显示丢弃单个文件更改的确认对话框
    @State private var showDiscardFileAlert = false

    /// 要丢弃更改的文件
    @State private var fileToDiscard: GitDiffFile?

    /// 是否显示丢弃所有更改的确认对话框
    @State private var showDiscardAllAlert = false

    /// 上次刷新时间，用于防抖控制
    @State private var lastRefreshTime: Date = Date.distantPast

    var body: some View {
        VStack(spacing: 0) {
            fileInfoBar
            fileListView
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.commit, onCommitChange)
        .onChange(of: selection, onSelectionChange)
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onApplicationDidBecomeActive(perform: onAppDidBecomeActive)
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
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12))
                    Text("丢弃所有更改")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .help("丢弃所有文件的更改")
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
                    scrollProxy.scrollTo(data.file, anchor: .top)
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
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                // 在后台执行耗时操作
                try await project.discardFileChanges(file.file)

                // 在主线程更新 UI
                await MainActor.run {
                    self.m.info("已丢弃文件更改: \(file.file)")
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardChanges")
            } catch {
                await MainActor.run {
                    self.m.error(error)
                }
            }
        }
    }

    /// 丢弃所有文件的更改
    func discardAllChanges() {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                // 在后台执行耗时操作
                try await project.discardAllChanges()

                // 在主线程更新 UI
                await MainActor.run {
                    self.m.info("已丢弃所有文件的更改")
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardAllChanges")
            } catch {
                await MainActor.run {
                    self.m.error(error)
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
        }

        guard let project = data.project else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }

        do {
            // 在后台线程执行耗时操作
            let (newFiles, selectedCommitHash) = try await Task.detached(priority: .userInitiated) {
                if Self.verbose {
                    os_log("\(self.t)🍋 Refreshing \(reason)")
                }

                // 检查任务是否被取消
                try Task.checkCancellation()

                let newFiles: [GitDiffFile]
                if let commit = await data.commit {
                    newFiles = try await project.changedFilesDetail(in: commit.hash)
                } else {
                    newFiles = try await project.untrackedFiles()
                }

                // 再次检查任务是否被取消
                try Task.checkCancellation()

                return (newFiles, await data.commit?.hash)
            }.value

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
                self.data.setFile(self.selection)
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
                self.m.error(error)
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

    /// 提交变更时的事件处理
    func onCommitChange() {
        Task {
            await self.refresh(reason: "OnCommitChanged")
        }
    }

    /// 选中文件变更时的事件处理
    func onSelectionChange() {
        self.data.setFile(self.selection)
    }

    /// 项目提交完成时的事件处理
    /// - Parameter eventInfo: 项目事件信息
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        Task {
            await self.refresh(reason: "OnProjectDidCommit")
        }
    }

    /// 应用变为活跃状态时的事件处理
    func onAppDidBecomeActive() {
        Task {
            await self.refresh(reason: "OnAppDidBecomeActive")
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
