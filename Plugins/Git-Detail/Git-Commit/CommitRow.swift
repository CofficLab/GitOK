import LibGit2Swift
import MagicKit
import MagicAlert
import OSLog
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

    /// 是否可以撤销（第一个提交 + 未推送 + 无标签 + 有父提交）
    /// 与 GitHub Desktop 保持一致：只允许撤销最新的提交
    private var canUndo: Bool {
        isFirstCommit && isUnpushed && commit.tags.isEmpty && !commit.parentHashes.isEmpty
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
            // 右键菜单：撤销提交
            .contextMenu {
                if canUndo {
                    Button(role: .destructive) {
                        showUndoConfirmation = true
                    } label: {
                        Label("撤销提交", systemImage: "arrow.uturn.backward")
                    }
                }
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

        isUndoing = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.undoCommit(commit)

                if Self.verbose {
                    os_log("\(self.t)✅ Commit undone: \(commit.hash.prefix(8))")
                }

                await MainActor.run {
                    isUndoing = false
                    showUndoConfirmation = false
                    // 撤销后取消选中 commit，显示工作区变更
                    data.setCommit(nil)
                }
            } catch {
                await MainActor.run {
                    isUndoing = false
                    showUndoConfirmation = false
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
