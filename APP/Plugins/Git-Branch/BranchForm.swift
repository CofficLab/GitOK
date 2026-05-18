import AppKit
import MagicKit
import GitCoreKit
import LibGit2Swift
import MagicAlert
import OSLog
import ProjectRulesKit
import SwiftUI

struct BranchForm: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    
    
    @State private var branches: [GitBranch] = []
    @State private var remoteBranches: [String] = []
    @State private var newBranchName: String = ""
    @State private var searchText = ""
    @State private var isCreating = false
    @State private var isLoading = false
    @State private var selectedBranch: GitBranch?
    @State private var compareBaseBranch: GitBranch?
    @State private var compareHeadBranch: GitBranch?
    @State private var branchCompare: GitBranchCompare?
    @State private var isComparing = false
    @State private var compareError: String?
    @State private var rebaseStatus: GitRebaseStatus = .inactive
    @State private var isRebaseActionRunning = false
    @State private var cherryPickStatus: GitCherryPickStatus = .inactive
    @State private var isCherryPickActionRunning = false
    @State private var branchToRename: GitBranch?
    @State private var branchToSetUpstream: GitBranch?
    @State private var branchToUnsetUpstream: GitBranch?
    @State private var remoteBranchToDelete: String?
    @State private var renameBranchName = ""
    @State private var selectedUpstreamBranch = ""
    @State private var showDeleteRemoteBranchAlert = false
    
    private let verbose = false
    
    var project: Project? { vm.project }
    private var filteredBranches: [GitBranch] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return branches }
        return branches.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredRemoteBranches: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return remoteBranches }
        return remoteBranches.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        if project != nil {
            ScrollView {
            VStack(spacing: 16) {
                // 新建分支区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("新建分支", tableName: "GitBranch")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        TextField(String(localized: "分支名称", table: "GitBranch"), text: $newBranchName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Image.add.inButtonWithAction {
                            createBranch()
                        }
                    }
                }
                
                Divider()

                TextField("搜索分支", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                // 分支列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("切换分支", tableName: "GitBranch")
                        .font(.headline)
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                            Spacer()
                        }
                        .frame(height: 60)
                    } else if filteredBranches.isEmpty {
                        Text("暂无分支", tableName: "GitBranch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 60)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredBranches) { branch in
                                    BranchRowView(
                                        branch: branch,
                                        isSelected: selectedBranch?.id == branch.id,
                                        onSwitch: {
                                            switchBranch(branch)
                                        },
                                        onDelete: {
                                            deleteBranch(branch)
                                        },
                                        onRename: {
                                            beginRename(branch)
                                        },
                                        onPublish: {
                                            publishBranch(branch)
                                        },
                                        onSetUpstream: {
                                            beginSetUpstream(branch)
                                        },
                                        onUnsetUpstream: {
                                            branchToUnsetUpstream = branch
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }

                if filteredRemoteBranches.isEmpty == false {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("远程分支", tableName: "GitBranch")
                            .font(.headline)

                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredRemoteBranches, id: \.self) { branchName in
                                    HStack {
                                        Image(systemName: "network")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 12))

                                        Text(branchName)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Button(role: .destructive) {
                                            remoteBranchToDelete = branchName
                                            showDeleteRemoteBranchAlert = true
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                }

                if branches.count >= 2 {
                    Divider()
                    compareSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(width: 520)
            .onAppear {
                loadBranches()
            }
            .sheet(item: $branchToRename) { branch in
                renameSheet(branch)
            }
            .sheet(item: $branchToSetUpstream) { branch in
                upstreamSheet(branch)
            }
            .alert("确认取消 upstream", isPresented: Binding(
                get: { branchToUnsetUpstream != nil },
                set: { if !$0 { branchToUnsetUpstream = nil } }
            )) {
                Button("取消", role: .cancel) {
                    branchToUnsetUpstream = nil
                }
                Button("确认", role: .destructive) {
                    if let branch = branchToUnsetUpstream {
                        unsetUpstream(branch)
                    }
                    branchToUnsetUpstream = nil
                }
            } message: {
                Text("取消后该分支不会再显示 ahead/behind 对比。")
            }
            .alert("确认删除远程分支", isPresented: $showDeleteRemoteBranchAlert) {
                Button("取消", role: .cancel) {
                    remoteBranchToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let branchName = remoteBranchToDelete {
                        deleteRemoteBranch(branchName)
                    }
                    remoteBranchToDelete = nil
                }
            } message: {
                Text("确定要删除远程分支 \"\(remoteBranchToDelete ?? "")\" 吗？该操作会推送删除请求到远端。")
            }
        }
    }

    private func renameSheet(_ branch: GitBranch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重命名分支")
                .font(.headline)

            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("新分支名称", text: $renameBranchName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("取消") {
                    branchToRename = nil
                }
                Button("重命名") {
                    renameBranch(branch)
                    branchToRename = nil
                }
                .disabled(renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func upstreamSheet(_ branch: GitBranch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置 upstream")
                .font(.headline)

            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)

            if remoteBranches.isEmpty {
                Text("暂无远程分支，请先 fetch 或添加远程仓库。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("上游分支", selection: $selectedUpstreamBranch) {
                    ForEach(remoteBranches, id: \.self) { branchName in
                        Text(branchName).tag(branchName)
                    }
                }
            }

            HStack {
                Spacer()
                Button("取消") {
                    branchToSetUpstream = nil
                }
                Button("设置") {
                    setUpstream(branch, upstreamBranch: selectedUpstreamBranch)
                    branchToSetUpstream = nil
                }
                .disabled(selectedUpstreamBranch.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private var compareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分支比较")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Base")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Picker("Base", selection: $compareBaseBranch) {
                        ForEach(branches) { branch in
                            Text(branch.name).tag(branch as GitBranch?)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                GridRow {
                    Text("Head")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 44, alignment: .leading)
                    HStack(spacing: 8) {
                        Picker("Head", selection: $compareHeadBranch) {
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch as GitBranch?)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        Button {
                            loadCompare()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compareBaseBranch?.id == compareHeadBranch?.id || isComparing)
                    }
                }
            }

            if isComparing {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let compareError {
                Text(compareError)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let branchCompare {
                compareResultView(branchCompare)
            } else {
                Text("选择 base/head 后查看 ahead/behind、提交与文件变化。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            rebaseControlView
            cherryPickControlView
        }
    }

    private func compareResultView(_ compare: GitBranchCompare) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Ahead \(compare.ahead)")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Behind \(compare.behind)")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("\(compare.files.count) 个文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if compare.commits.isEmpty && compare.files.isEmpty {
                Text("两个分支没有差异。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                if compare.commits.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Head 独有提交")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(compare.commits.prefix(5)) { commit in
                            HStack {
                                Text(String(commit.hash.prefix(7)))
                                    .font(.caption.monospaced())
                                    .foregroundColor(.secondary)
                                Text(commit.subject)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                if compare.files.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("变更文件")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(compare.files.prefix(6)) { file in
                            HStack {
                                Text(file.status)
                                    .font(.caption.monospaced())
                                    .foregroundColor(.secondary)
                                    .frame(width: 34, alignment: .leading)
                                Text(file.oldPath.map { "\($0) -> \(file.path)" } ?? file.path)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Button {
                    mergeComparedBranches()
                } label: {
                    Text("合并 Head 到 Base")
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.ahead == 0)

                Button {
                    startComparedRebase()
                } label: {
                    Text("Rebase Head 到 Base")
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.ahead == 0 || rebaseStatus.isRebasing)

                Button {
                    cherryPickComparedCommits()
                } label: {
                    Text("Cherry-pick Head 到 Base")
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.commits.isEmpty || cherryPickStatus.isCherryPicking)

                pullRequestActions(compare: compare)
            }
        }
    }

    @ViewBuilder
    private func pullRequestActions(compare: GitBranchCompare) -> some View {
        if let links = pullRequestLinks() {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pull Request")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button {
                        links.createURL.openInBrowser()
                    } label: {
                        Text("创建 PR")
                    }
                    .disabled(compare.ahead == 0)
                    .help("在 \(links.provider.rawValue) 打开 base/head 创建页面")

                    Button {
                        links.branchURL.openInBrowser()
                    } label: {
                        Text("打开当前分支 PR")
                    }
                    .help("在 \(links.provider.rawValue) 查找 head 分支相关 PR")

                    Button {
                        links.listURL.openInBrowser()
                    } label: {
                        Text("PR 列表")
                    }
                    .help("打开远程仓库 Pull Request 列表")

                    Button {
                        copyPullRequestURL(links.createURL)
                    } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(.borderless)
                    .disabled(compare.ahead == 0)
                    .help("复制创建 PR 链接")
                }

                HStack(spacing: 8) {
                    Label("Review / 通知", systemImage: "bell.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        links.reviewRequestsURL.openInBrowser()
                    } label: {
                        Text("Review 请求")
                    }
                    .help("在 \(links.provider.rawValue) 打开与当前账号相关的 PR review 请求筛选页")

                    Button {
                        links.commentsURL.openInBrowser()
                    } label: {
                        Text("评论")
                    }
                    .help("打开 PR 评论或活动相关筛选页")

                    Button {
                        links.notificationsURL.openInBrowser()
                    } label: {
                        Text("通知")
                    }
                    .help("打开 \(links.provider.rawValue) 的 PR 通知或活动入口")
                }

                Text("未读状态需要平台账号/API 授权；当前入口会跳转到托管平台的通知、review 和评论筛选页。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            Text("当前 remote 暂不支持生成 Pull Request 链接。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var rebaseControlView: some View {
        Group {
            if rebaseStatus.isRebasing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rebase 进行中")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let branchName = rebaseStatus.branchName {
                        Text(branchName)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }

                    if let currentStep = rebaseStatus.currentStep, let totalSteps = rebaseStatus.totalSteps {
                        Text("\(currentStep) / \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Button("继续 Rebase") {
                            continueRebase()
                        }
                        .disabled(isRebaseActionRunning)

                        Button("中止 Rebase", role: .destructive) {
                            abortRebase()
                        }
                        .disabled(isRebaseActionRunning)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var cherryPickControlView: some View {
        Group {
            if cherryPickStatus.isCherryPicking {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cherry-pick 进行中")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let commitHash = cherryPickStatus.commitHash {
                        Text(String(commitHash.prefix(8)))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Button("继续 Cherry-pick") {
                            continueCherryPick()
                        }
                        .disabled(isCherryPickActionRunning)

                        Button("中止 Cherry-pick", role: .destructive) {
                            abortCherryPick()
                        }
                        .disabled(isCherryPickActionRunning)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Action

extension BranchForm {
    private func createBranch() {
        guard let project = project, !newBranchName.isEmpty else { return }
        
        let branchName = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branchName.isEmpty else { return }
        
        isCreating = true
        
        Task.detached {
            do {
                try project.createBranch(branchName)
                
                await MainActor.run {
                    self.isCreating = false
                    self.newBranchName = ""
                    let msg = String.localizedStringWithFormat(
                        String(localized: "已创建并切换到分支: %@", table: "GitBranch"),
                        branchName
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    os_log(.error, "❌ 创建分支失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "创建分支失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }
    
    private func switchBranch(_ branch: GitBranch) {
        guard let project = project else { return }

        Task.detached {
            do {
                try project.checkout(branch: branch)
                
                await MainActor.run {
                    self.selectedBranch = branch
                    let msg = String.localizedStringWithFormat(
                        String(localized: "已切换到分支: %@", table: "GitBranch"),
                        branch.name
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 切换分支失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "切换分支失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }

    private func deleteBranch(_ branch: GitBranch) {
        guard let project = project else { return }
        guard selectedBranch?.id != branch.id else {
            alert_error("不能删除当前分支")
            return
        }

        Task.detached {
            do {
                try project.deleteLocalBranch(branch)

                await MainActor.run {
                    let msg = String.localizedStringWithFormat(
                        String(localized: "已删除分支: %@", table: "GitBranch"),
                        branch.name
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 删除分支失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "删除分支失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }

    private func beginRename(_ branch: GitBranch) {
        renameBranchName = branch.name
        branchToRename = branch
    }

    private func renameBranch(_ branch: GitBranch) {
        guard let project = project else { return }

        let newName = renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newName.isEmpty == false else { return }

        Task.detached {
            do {
                try project.renameBranch(branch, to: newName)

                await MainActor.run {
                    let msg = String.localizedStringWithFormat("已重命名分支: %@ -> %@", branch.name, newName)
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 重命名分支失败: \(error.localizedDescription)")
                    alert_error("重命名分支失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func beginSetUpstream(_ branch: GitBranch) {
        if selectedUpstreamBranch.isEmpty || remoteBranches.contains(selectedUpstreamBranch) == false {
            selectedUpstreamBranch = remoteBranches.first ?? ""
        }
        branchToSetUpstream = branch
    }

    private func publishBranch(_ branch: GitBranch) {
        guard let project = project else { return }

        Task.detached {
            do {
                try project.publishBranch(branch)

                await MainActor.run {
                    alert_info("已发布分支: \(branch.name)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 发布分支失败: \(error.localizedDescription)")
                    alert_error("发布分支失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setUpstream(_ branch: GitBranch, upstreamBranch: String) {
        guard let project = project else { return }

        Task.detached {
            do {
                try project.setUpstream(localBranch: branch, upstreamBranch: upstreamBranch)

                await MainActor.run {
                    alert_info("已设置 upstream: \(branch.name) -> \(upstreamBranch)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 设置 upstream 失败: \(error.localizedDescription)")
                    alert_error("设置 upstream 失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func unsetUpstream(_ branch: GitBranch) {
        guard let project = project else { return }

        Task.detached {
            do {
                try project.unsetUpstream(localBranch: branch)

                await MainActor.run {
                    alert_info("已取消 upstream: \(branch.name)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 取消 upstream 失败: \(error.localizedDescription)")
                    alert_error("取消 upstream 失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteRemoteBranch(_ branchName: String) {
        guard let project = project else { return }
        let parts = branchName.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            alert_error("远程分支格式无效")
            return
        }

        Task.detached {
            do {
                try project.deleteRemoteBranch(named: parts[1], remote: parts[0])

                await MainActor.run {
                    alert_info("已删除远程分支: \(branchName)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 删除远程分支失败: \(error.localizedDescription)")
                    alert_error("删除远程分支失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadCompare() {
        guard let project = project,
              let base = compareBaseBranch,
              let head = compareHeadBranch,
              base.id != head.id else { return }

        isComparing = true
        compareError = nil

        Task.detached(priority: .userInitiated) {
            do {
                let compare = try project.compareBranches(base: base, head: head)

                await MainActor.run {
                    self.branchCompare = compare
                    self.isComparing = false
                }
            } catch {
                await MainActor.run {
                    self.branchCompare = nil
                    self.compareError = error.localizedDescription
                    self.isComparing = false
                }
            }
        }
    }

    private func pullRequestLinks() -> RemoteRepositoryFormRules.PullRequestWebLinks? {
        guard let project = project,
              let base = compareBaseBranch,
              let head = compareHeadBranch,
              let remotes = try? project.remoteList() else {
            return nil
        }

        let preferredRemote = remotes.first(where: { $0.name == "origin" }) ?? remotes.first
        let remoteURL = preferredRemote?.url ?? preferredRemote?.fetchURL ?? preferredRemote?.pushURL
        guard let remoteURL else { return nil }

        return RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: remoteURL,
            baseBranch: base.name,
            headBranch: head.name
        )
    }

    private func copyPullRequestURL(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        alert_info("已复制 PR 链接")
    }

    private func mergeComparedBranches() {
        guard let project = project,
              let base = compareBaseBranch,
              let head = compareHeadBranch,
              base.id != head.id else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try project.mergeBranches(fromBranch: head, toBranch: base)

                await MainActor.run {
                    alert_info("已将 \(head.name) 合并到 \(base.name)")
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 分支比较合并失败: \(error.localizedDescription)")
                    alert_error("分支比较合并失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startComparedRebase() {
        guard let project = project,
              let base = compareBaseBranch,
              let head = compareHeadBranch,
              base.id != head.id else { return }

        isRebaseActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.startRebase(branch: head, onto: base)

                await MainActor.run {
                    alert_info("已将 \(head.name) rebase 到 \(base.name)")
                    self.isRebaseActionRunning = false
                    self.loadBranches()
                    self.loadRebaseStatus()
                    self.loadCompare()
                }
            } catch {
                let status = try? project.rebaseStatus()

                await MainActor.run {
                    self.isRebaseActionRunning = false
                    if let status {
                        self.rebaseStatus = status
                    }
                    if status?.isRebasing == true {
                        alert_error("Rebase 遇到冲突，请解决并暂存文件后继续。")
                    } else {
                        alert_error("Rebase 失败: \(error.localizedDescription)")
                    }
                    self.loadBranches()
                }
            }
        }
    }

    private func continueRebase() {
        guard let project = project, rebaseStatus.isRebasing else { return }
        isRebaseActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try await project.continueRebase()
                let status = try project.rebaseStatus()

                await MainActor.run {
                    self.rebaseStatus = status
                    self.isRebaseActionRunning = false
                    alert_info(status.isRebasing ? "Rebase 已继续，仍有步骤待处理" : "Rebase 已完成")
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                let status = try? project.rebaseStatus()

                await MainActor.run {
                    if let status {
                        self.rebaseStatus = status
                    }
                    self.isRebaseActionRunning = false
                    alert_error("继续 Rebase 失败: \(error.localizedDescription)")
                    self.loadBranches()
                }
            }
        }
    }

    private func abortRebase() {
        guard let project = project, rebaseStatus.isRebasing else { return }
        isRebaseActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try await project.abortRebase()

                await MainActor.run {
                    self.rebaseStatus = .inactive
                    self.isRebaseActionRunning = false
                    alert_info("已中止 Rebase")
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    self.isRebaseActionRunning = false
                    alert_error("中止 Rebase 失败: \(error.localizedDescription)")
                    self.loadRebaseStatus()
                }
            }
        }
    }

    private func cherryPickComparedCommits() {
        guard let project = project,
              let base = compareBaseBranch,
              let compare = branchCompare,
              compare.commits.isEmpty == false else { return }

        let commitHashes = compare.commits.reversed().map(\.hash)
        isCherryPickActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try project.cherryPick(commits: commitHashes, onto: base)

                await MainActor.run {
                    self.isCherryPickActionRunning = false
                    alert_info("已 Cherry-pick \(commitHashes.count) 个提交到 \(base.name)")
                    self.loadBranches()
                    self.loadCherryPickStatus()
                    self.loadCompare()
                }
            } catch {
                let status = try? project.cherryPickStatus()

                await MainActor.run {
                    self.isCherryPickActionRunning = false
                    if let status {
                        self.cherryPickStatus = status
                    }
                    if status?.isCherryPicking == true {
                        alert_error("Cherry-pick 遇到冲突，请解决并暂存文件后继续。")
                    } else {
                        alert_error("Cherry-pick 失败: \(error.localizedDescription)")
                    }
                    self.loadBranches()
                }
            }
        }
    }

    private func continueCherryPick() {
        guard let project = project, cherryPickStatus.isCherryPicking else { return }
        isCherryPickActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try await project.continueCherryPick()
                let status = try project.cherryPickStatus()

                await MainActor.run {
                    self.cherryPickStatus = status
                    self.isCherryPickActionRunning = false
                    alert_info(status.isCherryPicking ? "Cherry-pick 已继续，仍有提交待处理" : "Cherry-pick 已完成")
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                let status = try? project.cherryPickStatus()

                await MainActor.run {
                    if let status {
                        self.cherryPickStatus = status
                    }
                    self.isCherryPickActionRunning = false
                    alert_error("继续 Cherry-pick 失败: \(error.localizedDescription)")
                    self.loadBranches()
                }
            }
        }
    }

    private func abortCherryPick() {
        guard let project = project, cherryPickStatus.isCherryPicking else { return }
        isCherryPickActionRunning = true

        Task.detached(priority: .userInitiated) {
            do {
                try await project.abortCherryPick()

                await MainActor.run {
                    self.cherryPickStatus = .inactive
                    self.isCherryPickActionRunning = false
                    alert_info("已中止 Cherry-pick")
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    self.isCherryPickActionRunning = false
                    alert_error("中止 Cherry-pick 失败: \(error.localizedDescription)")
                    self.loadCherryPickStatus()
                }
            }
        }
    }
    
    private func loadBranches() {
        guard let project = project else {
            branches = []
            remoteBranches = []
            return
        }
        
        // 检查是否是 git 项目
        guard project.isGitRepo else {
            branches = []
            remoteBranches = []
            isLoading = false
            return
        }
        
        // 设置刷新状态
        isLoading = true
        
        Task.detached {
            do {
                let allBranches = try project.getBranches()
                let currentBranch = try project.getCurrentBranch()
                let remoteBranches = (try? project.remoteBranches()) ?? []
                let rebaseStatus = (try? project.rebaseStatus()) ?? .inactive
                let cherryPickStatus = (try? project.cherryPickStatus()) ?? .inactive
                
                await MainActor.run {
                    self.branches = allBranches
                    self.remoteBranches = remoteBranches
                    self.selectedBranch = currentBranch
                    self.rebaseStatus = rebaseStatus
                    self.cherryPickStatus = cherryPickStatus
                    self.updateCompareSelection(with: allBranches, currentBranch: currentBranch)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.branches = []
                    self.remoteBranches = []
                    self.isLoading = false
                    os_log(.error, "❌ 加载分支列表失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "加载分支列表失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }

    private func loadRebaseStatus() {
        guard let project = project else {
            rebaseStatus = .inactive
            return
        }

        Task.detached(priority: .userInitiated) {
            let status = (try? project.rebaseStatus()) ?? .inactive

            await MainActor.run {
                self.rebaseStatus = status
            }
        }
    }

    private func loadCherryPickStatus() {
        guard let project = project else {
            cherryPickStatus = .inactive
            return
        }

        Task.detached(priority: .userInitiated) {
            let status = (try? project.cherryPickStatus()) ?? .inactive

            await MainActor.run {
                self.cherryPickStatus = status
            }
        }
    }

    private func updateCompareSelection(with branches: [GitBranch], currentBranch: GitBranch?) {
        guard branches.count >= 2 else {
            compareBaseBranch = nil
            compareHeadBranch = nil
            branchCompare = nil
            return
        }

        if compareBaseBranch == nil || branches.contains(where: { $0.id == compareBaseBranch?.id }) == false {
            compareBaseBranch = currentBranch ?? branches.first
        }

        if compareHeadBranch == nil || branches.contains(where: { $0.id == compareHeadBranch?.id }) == false || compareHeadBranch?.id == compareBaseBranch?.id {
            compareHeadBranch = branches.first(where: { $0.id != compareBaseBranch?.id })
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
