import LibGit2Swift
import GitCoreKit
import MagicKit
import MagicAlert
import OSLog
import ProjectRulesKit
import SwiftUI

/// 提交记录行视图组件
/// 显示单个 Git 提交的详细信息，包括消息、作者、时间等
struct CommitRow: View, SuperThread, SuperLog {
    nonisolated static let emoji = "📝"
    nonisolated static let verbose = false

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 提交对象
    let commit: GitCommit

    /// 是否为列表中的第一个提交（最新的提交）
    let isFirstCommit: Bool

    /// 当前提交在已加载历史中的位置，HEAD 为 0。
    let commitIndex: Int

    /// 当前提交是否未推送
    private var isUnpushed: Bool {
        vm.isCommitUnpushed(commit.hash)
    }

    /// 标签文本
    @State private var tag: String = ""

    /// 头像用户列表
    @State private var avatarUsers: [AvatarUser] = []

    // MARK: - Push Popover State

    /// Popover 显示状态
    @State private var showPushPopover = false

    /// 推送中状态
    @State private var isPushing = false

    /// 推送错误信息
    @State private var pushError: Error?

    // MARK: - Undo State

    /// 是否显示撤销确认弹窗
    @State private var showUndoConfirmation = false

    /// 是否正在执行撤销操作
    @State private var isUndoing = false

    @State private var showRevertConfirmation = false
    @State private var showResetSoftConfirmation = false
    @State private var showResetMixedConfirmation = false
    @State private var showResetHardConfirmation = false
    @State private var showSquashConfirmation = false
    @State private var squashMessage = ""
    @State private var isRunningHistoryOperation = false

    /// 是否显示创建标签弹窗
    @State private var showCreateTagAlert = false

    /// 是否显示创建附注标签弹窗
    @State private var showCreateAnnotatedTagAlert = false

    /// 新标签名称
    @State private var newTagName = ""

    /// 新附注标签名称
    @State private var newAnnotatedTagName = ""

    /// 新附注标签说明
    @State private var newAnnotatedTagMessage = ""

    /// 是否正在创建标签
    @State private var isCreatingTag = false

    /// 是否正在创建附注标签
    @State private var isCreatingAnnotatedTag = false

    /// 是否显示删除标签确认弹窗
    @State private var showDeleteTagConfirmation = false

    /// 是否显示删除远端标签确认弹窗
    @State private var showDeleteRemoteTagConfirmation = false

    /// 是否正在删除标签
    @State private var isDeletingTag = false

    /// 是否正在删除远端标签
    @State private var isDeletingRemoteTag = false

    /// 是否正在推送标签
    @State private var isPushingTag = false

    /// 是否可以撤销（第一个提交 + 未推送 + 无标签 + 有父提交）
    /// 与 GitHub Desktop 保持一致：只允许撤销最新的提交
    private var canUndo: Bool {
        isFirstCommit && isUnpushed && commit.tags.isEmpty && !commit.parentHashes.isEmpty
    }

    private var canSquashThroughHead: Bool {
        commitIndex >= 1 && isUnpushed
    }

    var body: some View {
        commitRowContent
    }

    // MARK: - Private Properties

    /// Hover 状态
    @State private var isHovered = false

    /// 行背景颜色
    @ViewBuilder
    private var rowBackground: some View {
        if data.commit == self.commit {
            Color.accentColor.opacity(0.1)
        } else if isHovered {
            Color.primary.opacity(0.08)
        } else {
            Color.clear
        }
    }

    /// 提交行主要内容视图
    private var commitRowContent: some View {
        VStack(spacing: 0) {
            Button(action: selectCommit) {
                HStack(alignment: .center, spacing: 12) {
                    // 中间：主要内容
                    VStack(alignment: .leading, spacing: 2) {
                        // 第一行：提交消息标题
                        HStack {
                            Text(commit.message)
                                .lineLimit(1)
                                .font(.system(size: 13))
                            if !tag.isEmpty {
                                Text(tag)
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(3)
                            }
                            Spacer()
                        }

                        // 第二行：头像 + 作者（包括 Co-Authored-By）
                        HStack(spacing: 4) {
                            // 单个头像（只显示主作者）
                            if let firstUser = avatarUsers.first {
                                AvatarView(user: firstUser, size: 14)
                            }

                            // 作者文本
                            Text(commit.allAuthors)
                                .padding(.vertical, 1)
                                .lineLimit(1)

                            // 相对时间标签
                            Text(commit.date.smartRelativeTime)
                                .padding(.vertical, 1)
                                .padding(.horizontal, 1)

                            Spacer()
                        }
                        .padding(.vertical, 1)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                        // 第三行：提交时间（完整）
                        HStack {
                            Text(commit.date.fullDateTime)
                                .lineLimit(1)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.leading, 8)
                    .frame(minHeight: 25)

                    // 右侧：未推送到远程的操作按钮
                    if isUnpushed {
                        HStack(spacing: 4) {
                            // 撤销提交按钮
                            if canUndo {
                                AppIconButton(
                                    systemImage: "arrow.uturn.backward.circle",
                                    tint: .red,
                                    size: .regular
                                ) {
                                    showUndoConfirmation = true
                                }
                                .help("撤销此提交")
                            }

                            // 推送按钮
                            AppIconButton(
                                systemImage: "arrow.up.circle.fill",
                                tint: .orange,
                                size: .regular
                            ) {
                                showPushPopover = true
                            }
                            .help(String(localized: "点击推送到远程仓库", table: "GitCommit"))
                            .popover(isPresented: $showPushPopover) {
                                PushPopoverContent(
                                    isPushing: $isPushing,
                                    pushError: $pushError,
                                    onPush: performPush,
                                    onCancel: {
                                        showPushPopover = false
                                        pushError = nil
                                    }
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(rowBackground)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .onAppear(perform: onAppear)
            .onNotification(.appWillBecomeActive, onAppWillBecomeActive)
            .onProjectDidCommit(perform: onGitCommitSuccess)
            .onProjectGitRefsDidChange(perform: onGitRefsChanged)
            // 右键菜单：撤销提交
            .contextMenu {
                Button {
                    newTagName = ""
                    showCreateTagAlert = true
                } label: {
                    Label {
                        Text("创建标签", tableName: "GitCommit")
                    } icon: {
                        Image(systemName: "tag")
                    }
                }

                Button {
                    newAnnotatedTagName = ""
                    newAnnotatedTagMessage = ""
                    showCreateAnnotatedTagAlert = true
                } label: {
                    Label {
                        Text("创建附注标签", tableName: "GitCommit")
                    } icon: {
                        Image(systemName: "tag.fill")
                    }
                }

                if tag.isEmpty == false {
                    Button {
                        pushTag()
                    } label: {
                        Label {
                            Text("推送标签", tableName: "GitCommit")
                        } icon: {
                            Image(systemName: "arrow.up.circle")
                        }
                    }
                    .disabled(isPushingTag)

                    Button(role: .destructive) {
                        showDeleteRemoteTagConfirmation = true
                    } label: {
                        Label {
                            Text("删除远端标签", tableName: "GitCommit")
                        } icon: {
                            Image(systemName: "icloud.slash")
                        }
                    }
                    .disabled(isDeletingRemoteTag)

                    Button(role: .destructive) {
                        showDeleteTagConfirmation = true
                    } label: {
                        Label {
                            Text("删除标签", tableName: "GitCommit")
                        } icon: {
                            Image(systemName: "tag.slash")
                        }
                    }
                }

                if canUndo {
                    Button(role: .destructive) {
                        showUndoConfirmation = true
                    } label: {
                        Label("撤销提交", systemImage: "arrow.uturn.backward")
                    }
                }

                Divider()

                Button {
                    showRevertConfirmation = true
                } label: {
                    Label("Revert 此提交", systemImage: "arrow.counterclockwise")
                }
                .disabled(isRunningHistoryOperation)

                if canSquashThroughHead {
                    Button {
                        squashMessage = commit.message
                        showSquashConfirmation = true
                    } label: {
                        Label("Squash 到此提交", systemImage: "arrow.triangle.merge")
                    }
                    .disabled(isRunningHistoryOperation)
                }

                Menu {
                    Button {
                        showResetSoftConfirmation = true
                    } label: {
                        Label("Soft Reset", systemImage: "text.badge.checkmark")
                    }

                    Button {
                        showResetMixedConfirmation = true
                    } label: {
                        Label("Mixed Reset", systemImage: "list.bullet.rectangle")
                    }

                    Button(role: .destructive) {
                        showResetHardConfirmation = true
                    } label: {
                        Label("Hard Reset", systemImage: "trash")
                    }
                } label: {
                    Label("Reset 到此提交", systemImage: "arrow.down.to.line")
                }
                .disabled(isRunningHistoryOperation)
            }
            // 撤销确认弹窗
            .alert("确认撤销提交？", isPresented: $showUndoConfirmation) {
                Button("取消", role: .cancel) {}
                Button("撤销", role: .destructive) {
                    performUndo()
                }
            } message: {
                Text("撤销后，此提交的文件变更将保留在工作区中，可以重新编辑和提交。")
            }
            .alert("确认 Revert 此提交？", isPresented: $showRevertConfirmation) {
                Button("取消", role: .cancel) {}
                Button("Revert") {
                    performRevert()
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text("GitOK 会创建一个新的反向提交来撤销此提交的改动，适合已推送提交。若有冲突，需要手动解决后继续。")
            }
            .alert("确认 Soft Reset？", isPresented: $showResetSoftConfirmation) {
                Button("取消", role: .cancel) {}
                Button("Soft Reset") {
                    performReset(.soft)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text("HEAD 会移动到此提交，之后的提交改动会保留在暂存区。")
            }
            .alert("确认 Mixed Reset？", isPresented: $showResetMixedConfirmation) {
                Button("取消", role: .cancel) {}
                Button("Mixed Reset") {
                    performReset(.mixed)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text("HEAD 会移动到此提交，之后的提交改动会保留在工作区但取消暂存。")
            }
            .alert("确认 Hard Reset？", isPresented: $showResetHardConfirmation) {
                Button("取消", role: .cancel) {}
                Button("Hard Reset", role: .destructive) {
                    performReset(.hard)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text("HEAD、暂存区和工作区都会回到此提交。此提交之后的本地提交和未提交改动会被丢弃。")
            }
            .alert("确认 Squash 提交？", isPresented: $showSquashConfirmation) {
                TextField("Squash 后的提交信息", text: $squashMessage)
                Button("取消", role: .cancel) {}
                Button("Squash") {
                    performSquash()
                }
                .disabled(squashMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunningHistoryOperation)
            } message: {
                Text("会把从 HEAD 到此提交之间的 \(commitIndex + 1) 个提交合并为一个新提交。仅建议用于尚未推送的提交。")
            }
            .alert(String(localized: "创建标签", table: "GitCommit"), isPresented: $showCreateTagAlert) {
                TextField(String(localized: "标签名称", table: "GitCommit"), text: $newTagName)
                Button(String(localized: "取消", table: "GitCommit"), role: .cancel) {
                    newTagName = ""
                }
                Button(String(localized: "创建", table: "GitCommit")) {
                    createLightweightTag()
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreatingTag)
            } message: {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "为提交 %@ 创建 lightweight tag。", table: "GitCommit"),
                        String(commit.hash.prefix(8))
                    )
                )
            }
            .alert(String(localized: "创建附注标签", table: "GitCommit"), isPresented: $showCreateAnnotatedTagAlert) {
                TextField(String(localized: "标签名称", table: "GitCommit"), text: $newAnnotatedTagName)
                TextField(String(localized: "标签说明", table: "GitCommit"), text: $newAnnotatedTagMessage)
                Button(String(localized: "取消", table: "GitCommit"), role: .cancel) {
                    newAnnotatedTagName = ""
                    newAnnotatedTagMessage = ""
                }
                Button(String(localized: "创建", table: "GitCommit")) {
                    createAnnotatedTag()
                }
                .disabled(
                    newAnnotatedTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        newAnnotatedTagMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        isCreatingAnnotatedTag
                )
            } message: {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "为提交 %@ 创建 annotated tag。", table: "GitCommit"),
                        String(commit.hash.prefix(8))
                    )
                )
            }
            .alert(String(localized: "确认删除标签？", table: "GitCommit"), isPresented: $showDeleteTagConfirmation) {
                Button(String(localized: "取消", table: "GitCommit"), role: .cancel) {}
                Button(String(localized: "删除", table: "GitCommit"), role: .destructive) {
                    deleteLocalTag()
                }
                .disabled(isDeletingTag)
            } message: {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "将删除本地标签 %@，远程标签不会受影响。", table: "GitCommit"),
                        tag
                    )
                )
            }
            .alert(String(localized: "确认删除远端标签？", table: "GitCommit"), isPresented: $showDeleteRemoteTagConfirmation) {
                Button(String(localized: "取消", table: "GitCommit"), role: .cancel) {}
                Button(String(localized: "删除", table: "GitCommit"), role: .destructive) {
                    deleteRemoteTag()
                }
                .disabled(isDeletingRemoteTag)
            } message: {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "将删除 origin 上的标签 %@，本地标签不会受影响。", table: "GitCommit"),
                        tag
                    )
                )
            }

            Divider()
        }
    }

    // MARK: - Action

    /// 选择提交并设置为当前选中的提交
    private func selectCommit() {
        if Self.verbose {
            os_log("\(self.t)👆 Commit selected - hash: \(commit.hash.prefix(8)), message: \(commit.message.prefix(30))")
        }
        data.setCommit(commit)
    }

    /// 执行推送操作
    private func performPush() async throws {
        guard let project = vm.project else {
            throw NSError(domain: "GitOK", code: -1, userInfo: [
                NSLocalizedDescriptionKey: String(localized: "项目不可用", table: "GitCommit")
            ])
        }

        if Self.verbose {
            os_log("\(self.t)🚀 Pushing commit \(commit.hash.prefix(8)) to remote")
        }

        // 执行推送
        try project.push()

        // 注意：不再单独更新未推送状态，由父组件 CommitList 统一管理

        if Self.verbose {
            os_log("\(self.t)✅ Push completed successfully for commit \(commit.hash.prefix(8))")
        }
    }

    /// 执行撤销提交操作
    /// 使用 git reset --mixed 回退到父提交，文件变更保留在工作区
    private func performUndo() {
        guard let project = vm.project else {
            alert_error("项目不可用")
            return
        }

        let projectPath = project.path
        let commitSnapshot = commit

        isUndoing = true

        Task.detached(priority: .userInitiated) {
            do {
                guard let parentHash = commitSnapshot.parentHashes.first else {
                    throw NSError(
                        domain: "GitOK",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "暂不支持撤销初始提交"]
                    )
                }

                try LibGit2.reset(to: parentHash, mode: "mixed", at: projectPath, verbose: false)

                if Self.verbose {
                    os_log("\(self.t)✅ Commit undone: \(commitSnapshot.hash.prefix(8))")
                }

                await MainActor.run {
                    if let activeProject = vm.project, activeProject.path == projectPath {
                        activeProject.postEvent(
                            name: .projectDidCommit,
                            operation: "undoCommit",
                            additionalInfo: [
                                "commitHash": commitSnapshot.hash,
                                "parentHash": parentHash
                            ]
                        )
                    }
                    isUndoing = false
                    showUndoConfirmation = false
                    // 撤销后取消选中 commit，显示工作区变更
                    data.setCommit(nil)
                }
            } catch {
                await MainActor.run {
                    if let activeProject = vm.project, activeProject.path == projectPath {
                        activeProject.postEvent(
                            name: .projectOperationDidFail,
                            operation: "undoCommit",
                            success: false,
                            error: error,
                            additionalInfo: ["commitHash": commitSnapshot.hash]
                        )
                    }
                    isUndoing = false
                    showUndoConfirmation = false
                    alert_error(error)
                }
            }
        }
    }

    private func performRevert() {
        guard let project = vm.project else {
            alert_error("项目不可用")
            return
        }

        let commitSnapshot = commit
        isRunningHistoryOperation = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.revertCommit(commitSnapshot)
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showRevertConfirmation = false
                    data.setCommit(nil)
                    alert_info("已 Revert: \(commitSnapshot.hash.prefix(8))")
                }
            } catch {
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showRevertConfirmation = false
                    alert_error(error)
                }
            }
        }
    }

    private func performReset(_ mode: GitCoreKit.GitResetMode) {
        guard let project = vm.project else {
            alert_error("项目不可用")
            return
        }

        let commitSnapshot = commit
        isRunningHistoryOperation = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.reset(to: commitSnapshot, mode: mode)
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showResetSoftConfirmation = false
                    showResetMixedConfirmation = false
                    showResetHardConfirmation = false
                    data.setCommit(nil)
                    alert_info("已 \(mode.rawValue) reset 到: \(commitSnapshot.hash.prefix(8))")
                }
            } catch {
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showResetSoftConfirmation = false
                    showResetMixedConfirmation = false
                    showResetHardConfirmation = false
                    alert_error(error)
                }
            }
        }
    }

    private func performSquash() {
        guard let project = vm.project else {
            alert_error("项目不可用")
            return
        }

        let message = squashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEmpty == false else {
            alert_error("提交信息不能为空")
            return
        }

        let count = commitIndex + 1
        isRunningHistoryOperation = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.squashLastCommits(count: count, message: message)
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showSquashConfirmation = false
                    data.setCommit(nil)
                    alert_info("已 squash \(count) 个提交")
                }
            } catch {
                await MainActor.run {
                    isRunningHistoryOperation = false
                    showSquashConfirmation = false
                    alert_error(error)
                }
            }
        }
    }

    /// 为当前提交创建 lightweight tag。
    private func createLightweightTag() {
        guard let project = vm.project else {
            alert_error(String(localized: "项目不可用", table: "GitCommit"))
            return
        }

        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagName.isEmpty == false else {
            alert_error(String(localized: "标签名称不能为空", table: "GitCommit"))
            return
        }

        let commitHash = commit.hash
        isCreatingTag = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.createLightweightTag(named: tagName, commitHash: commitHash)

                await MainActor.run {
                    isCreatingTag = false
                    newTagName = ""
                    showCreateTagAlert = false
                    let message = String.localizedStringWithFormat(
                        String(localized: "已创建标签: %@", table: "GitCommit"),
                        tagName
                    )
                    alert_info(message)
                    Task {
                        await loadTag()
                    }
                }
            } catch {
                await MainActor.run {
                    isCreatingTag = false
                    alert_error(error)
                }
            }
        }
    }

    /// 为当前提交创建 annotated tag。
    private func createAnnotatedTag() {
        guard let project = vm.project else {
            alert_error(String(localized: "项目不可用", table: "GitCommit"))
            return
        }

        let tagName = newAnnotatedTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagName.isEmpty == false else {
            alert_error(String(localized: "标签名称不能为空", table: "GitCommit"))
            return
        }

        let tagMessage = newAnnotatedTagMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagMessage.isEmpty == false else {
            alert_error(String(localized: "标签说明不能为空", table: "GitCommit"))
            return
        }

        let commitHash = commit.hash
        isCreatingAnnotatedTag = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.createAnnotatedTag(named: tagName, commitHash: commitHash, message: tagMessage)

                await MainActor.run {
                    isCreatingAnnotatedTag = false
                    newAnnotatedTagName = ""
                    newAnnotatedTagMessage = ""
                    showCreateAnnotatedTagAlert = false
                    let message = String.localizedStringWithFormat(
                        String(localized: "已创建标签: %@", table: "GitCommit"),
                        tagName
                    )
                    alert_info(message)
                    Task {
                        await loadTag()
                    }
                }
            } catch {
                await MainActor.run {
                    isCreatingAnnotatedTag = false
                    alert_error(error)
                }
            }
        }
    }

    /// 删除当前提交显示的本地 tag。
    private func deleteLocalTag() {
        guard let project = vm.project else {
            alert_error(String(localized: "项目不可用", table: "GitCommit"))
            return
        }

        let tagName = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagName.isEmpty == false else {
            alert_error(String(localized: "标签名称不能为空", table: "GitCommit"))
            return
        }

        isDeletingTag = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.deleteLocalTag(named: tagName)

                await MainActor.run {
                    isDeletingTag = false
                    showDeleteTagConfirmation = false
                    let message = String.localizedStringWithFormat(
                        String(localized: "已删除标签: %@", table: "GitCommit"),
                        tagName
                    )
                    alert_info(message)
                    Task {
                        await loadTag()
                    }
                }
            } catch {
                await MainActor.run {
                    isDeletingTag = false
                    alert_error(error)
                }
            }
        }
    }

    /// 推送当前提交显示的 tag 到 origin。
    private func pushTag() {
        guard let project = vm.project else {
            alert_error(String(localized: "项目不可用", table: "GitCommit"))
            return
        }

        let tagName = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagName.isEmpty == false else {
            alert_error(String(localized: "标签名称不能为空", table: "GitCommit"))
            return
        }

        isPushingTag = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.pushTag(named: tagName)

                await MainActor.run {
                    isPushingTag = false
                    let message = String.localizedStringWithFormat(
                        String(localized: "已推送标签: %@", table: "GitCommit"),
                        tagName
                    )
                    alert_info(message)
                }
            } catch {
                await MainActor.run {
                    isPushingTag = false
                    alert_error(error)
                }
            }
        }
    }

    /// 删除 origin 上当前提交显示的 tag。
    private func deleteRemoteTag() {
        guard let project = vm.project else {
            alert_error(String(localized: "项目不可用", table: "GitCommit"))
            return
        }

        let tagName = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagName.isEmpty == false else {
            alert_error(String(localized: "标签名称不能为空", table: "GitCommit"))
            return
        }

        isDeletingRemoteTag = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.deleteRemoteTag(named: tagName)

                await MainActor.run {
                    isDeletingRemoteTag = false
                    showDeleteRemoteTagConfirmation = false
                    let message = String.localizedStringWithFormat(
                        String(localized: "已删除远端标签: %@", table: "GitCommit"),
                        tagName
                    )
                    alert_info(message)
                }
            } catch {
                await MainActor.run {
                    isDeletingRemoteTag = false
                    alert_error(error)
                }
            }
        }
    }

    // MARK: - Setter

    /// 设置标签文本
    /// - Parameter tag: 标签文本
    @MainActor
    private func setTag(_ tag: String) {
        self.tag = tag
    }

    /// 设置头像用户列表
    /// - Parameter users: 用户列表
    @MainActor
    private func setAvatarUsers(_ users: [AvatarUser]) {
        avatarUsers = users
    }

    // MARK: - Private Helpers

    /// 异步加载 commit 的 tag 信息
    private func loadTag() async {
        guard let project = vm.project else {
            setTag("")
            return
        }

        let commitHash = self.commit.hash

        Task.detached(priority: .userInitiated) {
            do {
                let tags = try project.getTags(commit: commitHash)
                let tagValue = tags.first ?? ""

                await self.setTag(tagValue)
            } catch {
                await self.setTag("")
            }
        }
    }

    private func onGitRefsChanged(_ eventInfo: ProjectEventInfo) {
        guard eventInfo.project.path == vm.project?.path else { return }
        Task {
            await loadTag()
        }
    }

    /// 解析提交的作者信息（包括 co-authors）
    private func loadAvatarUsers() async {
        let commit = self.commit

        Task.detached(priority: .userInitiated) {
            if Self.verbose {
                os_log("\(Self.t)👤 Loading avatar users for commit: \(commit.hash.prefix(8))")
            }

            var users: [AvatarUser] = []

            // 解析作者信息
            let authorName: String
            let authorEmail: String

            // author 格式可能是 "name <email>" 或只是 "name"
            if let emailRange = commit.author.range(of: "<([^>]+)>", options: .regularExpression) {
                // 有邮箱
                let emailStartIndex = commit.author.index(emailRange.lowerBound, offsetBy: 1)
                let emailEndIndex = commit.author.index(emailRange.upperBound, offsetBy: -1)
                authorEmail = String(commit.author[emailStartIndex ..< emailEndIndex])

                let nameEndIndex = commit.author.index(emailRange.lowerBound, offsetBy: -2)
                authorName = String(commit.author[..<nameEndIndex]).trimmingCharacters(in: .whitespaces)
            } else {
                // 没有邮箱，使用 author 作为 name
                authorName = commit.author
                authorEmail = ""
            }

            // 添加主作者
            let author = AvatarUser(
                name: authorName,
                email: authorEmail
            )
            users.append(author)

            // 解析 co-authors
            let coAuthors = await self.parseCoAuthors(from: commit.message)
            users.append(contentsOf: coAuthors)

            // 去重（基于邮箱）
            var seenEmails = Set<String>()
            var uniqueUsers: [AvatarUser] = []

            for user in users {
                if !seenEmails.contains(user.email) {
                    seenEmails.insert(user.email)
                    uniqueUsers.append(user)
                }
            }

            await self.setAvatarUsers(uniqueUsers)
        }
    }

    /// 从 commit 消息中解析 co-authors
    /// - Parameter message: commit 消息
    /// - Returns: co-author 列表
    private func parseCoAuthors(from message: String) -> [AvatarUser] {
        var coAuthors: [AvatarUser] = []

        // Co-authored-by 格式：Co-authored-by: name <email>
        let pattern = #"Co-authored-by:\s*([^<]+?)\s*<([^>]+)>"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(message.startIndex..., in: message)
            let matches = regex.matches(in: message, range: range)

            for match in matches {
                if match.numberOfRanges >= 3 {
                    let nameRange = Range(match.range(at: 1), in: message)!
                    let emailRange = Range(match.range(at: 2), in: message)!

                    let name = String(message[nameRange]).trimmingCharacters(in: .whitespaces)
                    let email = String(message[emailRange]).trimmingCharacters(in: .whitespaces)

                    coAuthors.append(AvatarUser(name: name, email: email))
                }
            }
        }

        if Self.verbose && !coAuthors.isEmpty {
            os_log("\(self.t)👥 Parsed co-authors for commit \(commit.hash.prefix(8)): \(coAuthors.count) authors")
        }

        return coAuthors
    }

    // MARK: - Event Handler

    /// 视图出现时初始化状态
    func onAppear() {
        Task {
            await loadAvatarUsers()
            await loadTag()
        }
    }

    /// 应用变为活跃状态时重新加载标签
    func onAppWillBecomeActive(_ n: Notification) {
        Task {
            await loadTag()
        }
    }

    /// Git 提交成功时重新加载标签
    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        if Self.verbose {
            os_log("\(self.t)✨ Git commit success - reloading tag for commit: \(commit.hash.prefix(8))")
        }
        Task {
            await loadTag()
        }
    }
}

// MARK: - Push Popover View

/// 推送 Popover 内容视图（简洁模式）
struct PushPopoverContent: View {
    @Binding var isPushing: Bool
    @Binding var pushError: Error?
    let onPush: () async throws -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                Text("推送到远程", tableName: "GitCommit")
                    .font(.headline)
                Spacer()
            }

            Divider()

            if isPushing {
                // 推送中状态
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("正在推送中...", tableName: "GitCommit")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 60)
            } else {
                // 正常或错误状态
                VStack(alignment: .leading, spacing: 12) {
                    // 提示信息
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("当前提交尚未推送到远程", tableName: "GitCommit")
                            .font(.body)
                    }

                    // 错误信息（如果有）
                    if let error = pushError {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("推送失败", tableName: "GitCommit")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            Text(String.localizedStringWithFormat(
                                String(localized: "推送失败", table: "GitCommit") + ": %@",
                                error.localizedDescription
                            ))
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }

                    // 按钮组
                    HStack(spacing: 12) {
                        AppButton(
                            LocalizedStringKey(String(localized: "取消", table: "GitCommit")),
                            style: .secondary,
                            size: .small
                        ) {
                            onCancel()
                        }
                        .keyboardShortcut(.cancelAction)
                        
                        AppButton(
                            LocalizedStringKey(pushError == nil ? String(localized: "推送", table: "GitCommit") : String(localized: "重试", table: "GitCommit")),
                            style: .primary,
                            size: .small
                        ) {
                            Task {
                                do {
                                    isPushing = true
                                    pushError = nil
                                    try await onPush()
                                    // 立即关闭（用户选择的模式）
                                    dismiss()
                                } catch {
                                    isPushing = false
                                    pushError = error
                                }
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(isPushing)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(width: 280, height: pushError != nil ? 200 : (isPushing ? 160 : 180))
        .background(Color(nsColor: .windowBackgroundColor))
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
