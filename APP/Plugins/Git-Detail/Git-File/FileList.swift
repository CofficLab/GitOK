import AppKit
import GitCoreKit
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

    @State private var hoveredFile: GitDiffFile?

    @State private var stagedFilePaths: Set<String> = []

    @State private var unstagedFilePaths: Set<String> = []

    @State private var untrackedFilePaths: Set<String> = []

    /// 当前的刷新任务，用于取消之前的刷新操作
    @State private var refreshTask: Task<Void, Never>?
    /// 后台刷新工作任务
    @State private var refreshWorkerTask: Task<([GitDiffFile], String?, [GitStatusEntry]), Error>?

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

    /// 文件过滤文本
    @State private var filterText = ""

    /// 批量操作选择的文件路径
    @State private var selectedBatchFilePaths: Set<String> = []

    /// 是否显示批量丢弃确认
    @State private var showDiscardSelectedAlert = false

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
        .onProjectDidAddFiles(perform: onProjectDidAddFiles)
        .onProjectGitIndexDidChange(perform: onGitDirectoryDidChange)
        .onProjectGitHeadDidChange(perform: onGitDirectoryDidChange)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
        .alert(String(localized: "Confirm Discard All Changes"), isPresented: $showDiscardAllAlert) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Discard All"), role: .destructive) {
                discardAllChanges()
            }
        } message: {
            Text(discardAllAlertMessage)
        }
        .alert(String(localized: "Confirm Discard Selected Changes"), isPresented: $showDiscardSelectedAlert) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Discard Selected"), role: .destructive) {
                discardSelectedChanges()
            }
        } message: {
            Text(discardSelectedAlertMessage)
        }
    }
}

// MARK: - View

extension FileList {
    /// 文件信息栏：显示文件数量和加载状态
    private var fileInfoBar: some View {
        VStack(spacing: 6) {
            HStack {
                if data.commit == nil && !files.isEmpty {
                    Button(action: {
                        showDiscardAllAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12))
                            Text(String(localized: "Discard All Changes"))
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
                    .help(String(localized: "Discard changes of all files"))
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
                        Text(String(localized: "Loading..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image.doc
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        Text("\(files.count) \(String(localized: "files"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField(String(localized: "Filter files"), text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.caption)

                if filterText.isEmpty == false {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Clear filter"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.75))
            )
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
            if filteredFiles.isEmpty {
                emptyFilterState
            } else {
                List(selection: $selection) {
                    if data.commit == nil {
                        if changesFiles.isEmpty == false {
                            Section {
                                ForEach(changesFiles, id: \.self) { file in
                                    fileRow(file)
                                }
                            } header: {
                                sectionHeader(title: String(localized: "Changes"), count: changesFiles.count)
                            }
                        }

                        if stagedFilesForSection.isEmpty == false {
                            Section {
                                ForEach(stagedFilesForSection, id: \.self) { file in
                                    fileRow(file)
                                }
                            } header: {
                                sectionHeader(title: String(localized: "Staged Changes"), count: stagedFilesForSection.count)
                            }
                        }
                    } else {
                        Section {
                            ForEach(filteredFiles, id: \.self) { file in
                                fileRow(file)
                            }
                        } header: {
                            sectionHeader(title: String(localized: "History Files"), count: filteredFiles.count)
                    }
            }

            if data.commit == nil && selectedBatchFilePaths.isEmpty == false {
                batchActionBar
            }
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

    private var batchActionBar: some View {
        HStack(spacing: 8) {
            Text("\(String(localized: "Selected")) \(selectedBatchFiles.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()

            Button(String(localized: "Stage")) {
                stageSelectedFiles()
            }
            .disabled(selectedStageableFiles.isEmpty)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .accessibilityHint(String(localized: "Stage files that can still be staged in the batch selection"))

            Button(String(localized: "Unstage")) {
                unstageSelectedFiles()
            }
            .disabled(selectedUnstageableFiles.isEmpty)
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .accessibilityHint(String(localized: "Unstage already staged files in the batch selection"))

            Button(String(localized: "Discard"), role: .destructive) {
                showDiscardSelectedAlert = true
            }
            .disabled(selectedBatchFiles.isEmpty)
            .keyboardShortcut(.delete, modifiers: [.command])
            .accessibilityHint(String(localized: "Discard changes of files in the batch selection"))

            Spacer()

            Button(String(localized: "Select All Current")) {
                selectFilteredFiles()
            }
            .disabled(filteredFiles.isEmpty)
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .accessibilityHint(String(localized: "Select all files in the current filter result"))

            Button(String(localized: "Clear Selection")) {
                selectedBatchFilePaths.removeAll()
            }
            .accessibilityHint(String(localized: "Clear current batch selection"))
        }
        .font(.caption)
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.08))
        )
    }

    private var emptyFilterState: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(filterText.isEmpty ? String(localized: "No files changed") : String(localized: "No matching files"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
            Spacer()
            Text("\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .textCase(nil)
        .padding(.vertical, 2)
    }

    private func fileRow(_ file: GitDiffFile) -> some View {
        FileTile(
            file: file,
            onDiscardChanges: data.commit == nil ? {
                discardChanges(for: $0)
            } : nil,
            stageState: stageState(for: file),
            showsStageBadge: data.commit == nil,
            isBatchSelected: selectedBatchFilePaths.contains(file.file),
            onToggleBatchSelection: data.commit == nil ? {
                toggleBatchSelection(for: $0)
            } : nil,
            onStage: data.commit == nil ? {
                stageFile($0)
            } : nil,
            onUnstage: data.commit == nil ? {
                unstageFile($0)
            } : nil,
            onSelect: {
                selection = $0
                vm.setFile($0)
            },
            onHoverChanged: { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    if hovering {
                        hoveredFile = file
                    } else if hoveredFile == file {
                        hoveredFile = nil
                    }
                }
            }
        )
        .tag(file as GitDiffFile?)
        .listRowInsets(.init()) // 移除 List 的默认内边距
        .listRowBackground(
            hoveredFile == file ? Color.accentColor.opacity(0.10) : Color.clear
        )
        .accessibilityAddTraits(selection == file ? .isSelected : [])
        .onMoveCommand { direction in
            moveSelection(direction)
        }
        .onDeleteCommand {
            if let selection, data.commit == nil {
                fileToDiscard = selection
                showDiscardFileAlert = true
            }
        }
    }
}

// MARK: - Action

extension FileList {
    var filteredFiles: [GitDiffFile] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return files }
        return files.filter { $0.file.localizedCaseInsensitiveContains(query) }
    }

    var changesFiles: [GitDiffFile] {
        filteredFiles.filter { file in
            let state = stageState(for: file)
            return state == .unstaged || state == .stagedAndUnstaged
        }
    }

    var stagedFilesForSection: [GitDiffFile] {
        filteredFiles.filter { stageState(for: $0) == .staged }
    }

    var selectedBatchFiles: [GitDiffFile] {
        files.filter { selectedBatchFilePaths.contains($0.file) }
    }

    var selectedStageableFiles: [GitDiffFile] {
        selectedBatchFiles.filter { stageState(for: $0).canStage }
    }

    var selectedUnstageableFiles: [GitDiffFile] {
        selectedBatchFiles.filter { stageState(for: $0).canUnstage }
    }

    var discardSelectedAlertMessage: String {
        let count = selectedBatchFiles.count
        let untrackedCount = selectedBatchFiles.filter { untrackedFilePaths.contains($0.file) }.count
        if untrackedCount > 0 {
            return String(localized: "Are you sure you want to discard changes for \(count) files? \(untrackedCount) untracked files will be deleted. This action cannot be undone.")
        }
        return String(localized: "Are you sure you want to discard changes for \(count) files? This action cannot be undone.")
    }

    func toggleBatchSelection(for file: GitDiffFile) {
        if selectedBatchFilePaths.contains(file.file) {
            selectedBatchFilePaths.remove(file.file)
        } else {
            selectedBatchFilePaths.insert(file.file)
        }
    }

    func selectFilteredFiles() {
        selectedBatchFilePaths.formUnion(filteredFiles.map(\.file))
    }

    func moveSelection(_ direction: MoveCommandDirection) {
        guard filteredFiles.isEmpty == false else { return }

        let currentIndex = selection.flatMap { selected in
            filteredFiles.firstIndex(of: selected)
        }

        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = max((currentIndex ?? 0) - 1, 0)
        case .down:
            nextIndex = min((currentIndex ?? -1) + 1, filteredFiles.count - 1)
        default:
            return
        }

        let nextFile = filteredFiles[nextIndex]
        selection = nextFile
        vm.setFile(nextFile)
    }

    func stageState(for file: GitDiffFile) -> FileStageState {
        let isStaged = stagedFilePaths.contains(file.file)
        let isUnstaged = unstagedFilePaths.contains(file.file)

        if isStaged && isUnstaged {
            return .stagedAndUnstaged
        }

        if isStaged {
            return .staged
        }

        return .unstaged
    }

    var discardAllAlertMessage: String {
        var details: [String] = []
        if stagedFilePaths.isEmpty == false {
            details.append(String(localized: "\(stagedFilePaths.count) staged files"))
        }
        if unstagedFilePaths.isEmpty == false {
            details.append(String(localized: "\(unstagedFilePaths.count) unstaged files"))
        }
        if untrackedFilePaths.isEmpty == false {
            details.append(String(localized: "\(untrackedFilePaths.count) untracked files will be deleted"))
        }

        let summary = details.isEmpty ? String(localized: "\(files.count) files") : details.joined(separator: ", ")
        return String(localized: "Are you sure you want to discard all changes? This will affect \(summary). This action cannot be undone.")
    }


    func stageFile(_ file: GitDiffFile) {
        guard let project = vm.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try project.addFiles([file.file])
                await MainActor.run {
                    alert_info(String(localized: "Staged: \(file.file)"))
                }
                await self.refresh(reason: "AfterStageFile")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Stage file failed: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    func stageSelectedFiles() {
        let filesToStage = selectedStageableFiles
        guard let project = vm.project, filesToStage.isEmpty == false else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try project.addFiles(filesToStage.map(\.file))
                await MainActor.run {
                    alert_info(String(localized: "Staged \(filesToStage.count) files"))
                    selectedBatchFilePaths.subtract(filesToStage.map(\.file))
                }
                await self.refresh(reason: "AfterStageSelectedFiles")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Batch stage failed: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    func unstageFile(_ file: GitDiffFile) {
        guard let project = vm.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try project.unstageFiles([file.file])
                await MainActor.run {
                    alert_info(String(localized: "Unstaged: \(file.file)"))
                }
                await self.refresh(reason: "AfterUnstageFile")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Unstage file failed: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    func unstageSelectedFiles() {
        let filesToUnstage = selectedUnstageableFiles
        guard let project = vm.project, filesToUnstage.isEmpty == false else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try project.unstageFiles(filesToUnstage.map(\.file))
                await MainActor.run {
                    alert_info(String(localized: "Unstaged \(filesToUnstage.count) files"))
                    selectedBatchFilePaths.subtract(filesToUnstage.map(\.file))
                }
                await self.refresh(reason: "AfterUnstageSelectedFiles")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Batch unstage failed: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

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
                    alert_info(String(localized: "Discarded file changes: \(file.file)"))
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardChanges")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to discard file changes: \(error.localizedDescription)")
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
                    alert_info(String(localized: "Discarded all file changes"))
                }

                // 刷新文件列表（refresh 内部已经处理了后台线程）
                await self.refresh(reason: "AfterDiscardAllChanges")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to discard all changes: \(error.localizedDescription)")
                    alert_error(error)
                }
            }
        }
    }

    func discardSelectedChanges() {
        let filesToDiscard = selectedBatchFiles
        guard let project = vm.project, filesToDiscard.isEmpty == false else { return }

        Task.detached(priority: .userInitiated) {
            do {
                for file in filesToDiscard {
                    try project.discardFileChanges(file.file)
                }

                await MainActor.run {
                    alert_info(String(localized: "Discarded changes for \(filesToDiscard.count) files"))
                    selectedBatchFilePaths.subtract(filesToDiscard.map(\.file))
                }

                await self.refresh(reason: "AfterDiscardSelectedChanges")
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to batch discard: \(error.localizedDescription)")
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
                let statusEntries: [GitStatusEntry]
                if let hash = currentCommitHash {
                    newFiles = try await project.changedFilesDetail(in: hash)
                    statusEntries = []
                } else {
                    newFiles = try await project.untrackedFiles()
                    statusEntries = try project.statusEntries()
                }

                // 再次检查任务是否被取消
                try Task.checkCancellation()

                return (newFiles, currentCommitHash, statusEntries)
            }
            refreshWorkerTask = worker
            let (newFiles, selectedCommitHash, statusEntries) = try await worker.value

            // 在主线程更新 UI
            await MainActor.run {
                // 确保在刷新过程中 commit 没有变化
                guard selectedCommitHash == self.data.commit?.hash else {
                    if Self.verbose {
                        os_log("\(self.t)🔄 Commit changed during refresh, skipping UI update")
                    }
                    return
                }

                let selectedFilePath = self.selection?.file ?? self.vm.file?.file
                let refreshedSelection = selectedFilePath.flatMap { path in
                    newFiles.first { $0.file == path }
                } ?? newFiles.first

                self.files = newFiles
                self.stagedFilePaths = Set(statusEntries.filter { $0.indexStatus != " " && $0.indexStatus != "?" }.map(\.path))
                self.unstagedFilePaths = Set(statusEntries.filter { $0.workTreeStatus != " " || $0.indexStatus == "?" }.map(\.path))
                self.untrackedFilePaths = Set(statusEntries.filter { $0.indexStatus == "?" }.map(\.path))
                self.selectedBatchFilePaths = self.selectedBatchFilePaths.intersection(Set(newFiles.map(\.file)))
                self.selection = refreshedSelection
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
                os_log(.error, "\(Self.t)❌ Failed to refresh file list: \(gitDetailError.localizedDescription)")
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

    func onProjectDidAddFiles(_ eventInfo: ProjectEventInfo) {
        guard eventInfo.project.path == vm.project?.path else { return }
        Task {
            await self.refresh(reason: "OnProjectDidAddFiles")
        }
    }

    /// .git 目录发生变化时刷新文件列表
    /// - Parameter eventInfo: 项目事件信息
    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        guard eventInfo.project.path == vm.project?.path else { return }
        Task {
            await self.refresh(reason: "OnGitDirectoryDidChange")
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
