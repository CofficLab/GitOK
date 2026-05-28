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
    @State private var branchCompare: GitCoreKit.GitBranchCompare?
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
                // New branch area
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "New Branch", table: "GitBranch"))
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        TextField(String(localized: "Branch name", table: "GitBranch"), text: $newBranchName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Image.add.inButtonWithAction {
                            createBranch()
                        }
                    }
                }
                
                Divider()

                TextField(String(localized: "Search branches", table: "GitBranch"), text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                // 分支列表
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Switch Branch", table: "GitBranch"))
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
                        Text(String(localized: "No branches yet", table: "GitBranch"))
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
                        Text(String(localized: "Remote Branches", table: "GitBranch"))
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
            .alert(String(localized: "Confirm Unset Upstream", table: "GitBranch"), isPresented: Binding(
                get: { branchToUnsetUpstream != nil },
                set: { if !$0 { branchToUnsetUpstream = nil } }
            )) {
                Button(String(localized: "Cancel", table: "GitBranch"), role: .cancel) {
                    branchToUnsetUpstream = nil
                }
                Button(String(localized: "Confirm", table: "GitBranch"), role: .destructive) {
                    if let branch = branchToUnsetUpstream {
                        unsetUpstream(branch)
                    }
                    branchToUnsetUpstream = nil
                }
            } message: {
                Text(String(localized: "After unsetting, this branch will no longer show ahead/behind comparison.", table: "GitBranch"))
            }
            .alert(String(localized: "Confirm Delete Remote Branch", table: "GitBranch"), isPresented: $showDeleteRemoteBranchAlert) {
                Button(String(localized: "Cancel", table: "GitBranch"), role: .cancel) {
                    remoteBranchToDelete = nil
                }
                Button(String(localized: "Delete", table: "GitBranch"), role: .destructive) {
                    if let branchName = remoteBranchToDelete {
                        deleteRemoteBranch(branchName)
                    }
                    remoteBranchToDelete = nil
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete remote branch \"\(remoteBranchToDelete ?? "")\"? This will push a delete request to the remote.", table: "GitBranch"))
            }
        }
    }

    private func renameSheet(_ branch: GitBranch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Rename Branch", table: "GitBranch"))
                .font(.headline)

            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(String(localized: "New branch name", table: "GitBranch"), text: $renameBranchName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button(String(localized: "Cancel", table: "GitBranch")) {
                    branchToRename = nil
                }
                Button(String(localized: "Rename", table: "GitBranch")) {
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
            Text(String(localized: "Set Upstream", table: "GitBranch"))
                .font(.headline)

            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)

            if remoteBranches.isEmpty {
                Text(String(localized: "No remote branches available. Fetch or add a remote first.", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker(String(localized: "Upstream branch", table: "GitBranch"), selection: $selectedUpstreamBranch) {
                    ForEach(remoteBranches, id: \.self) { branchName in
                        Text(branchName).tag(branchName)
                    }
                }
            }

            HStack {
                Spacer()
                Button(String(localized: "Cancel", table: "GitBranch")) {
                    branchToSetUpstream = nil
                }
                Button(String(localized: "Set", table: "GitBranch")) {
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
            Text(String(localized: "Branch Compare", table: "GitBranch"))
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
                Text(String(localized: "Select base/head to view ahead/behind counts, commits, and file changes.", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            rebaseControlView
            cherryPickControlView
        }
    }

    private func compareResultView(_ compare: GitCoreKit.GitBranchCompare) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(String(localized: "Ahead \(compare.ahead)", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.green)
                Text(String(localized: "Behind \(compare.behind)", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(String(localized: "\(compare.files.count) files", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if compare.commits.isEmpty && compare.files.isEmpty {
                Text(String(localized: "No differences between the two branches.", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                if compare.commits.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Head unique commits", table: "GitBranch"))
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
                        Text(String(localized: "Changed files", table: "GitBranch"))
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
                    Text(String(localized: "Merge Head into Base", table: "GitBranch"))
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.ahead == 0)

                Button {
                    startComparedRebase()
                } label: {
                    Text(String(localized: "Rebase Head onto Base", table: "GitBranch"))
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.ahead == 0 || rebaseStatus.isRebasing)

                Button {
                    cherryPickComparedCommits()
                } label: {
                    Text(String(localized: "Cherry-pick Head into Base", table: "GitBranch"))
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.commits.isEmpty || cherryPickStatus.isCherryPicking)

                pullRequestActions(compare: compare)
            }
        }
    }

    @ViewBuilder
    private func pullRequestActions(compare: GitCoreKit.GitBranchCompare) -> some View {
        if let links = pullRequestLinks() {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Pull Request", table: "GitBranch"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button {
                        links.createURL.openInBrowser()
                    } label: {
                        Text(String(localized: "Create PR", table: "GitBranch"))
                    }
                    .disabled(compare.ahead == 0)
                    .help(String(localized: "Open base/head creation page on \(links.provider.rawValue)", table: "GitBranch"))

                    Button {
                        links.branchURL.openInBrowser()
                    } label: {
                        Text(String(localized: "Open Branch PR", table: "GitBranch"))
                    }
                    .help(String(localized: "Find head branch related PR on \(links.provider.rawValue)", table: "GitBranch"))

                    Button {
                        links.listURL.openInBrowser()
                    } label: {
                        Text(String(localized: "PR List", table: "GitBranch"))
                    }
                    .help(String(localized: "Open remote repository Pull Request list", table: "GitBranch"))

                    Button {
                        copyPullRequestURL(links.createURL)
                    } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(.borderless)
                    .disabled(compare.ahead == 0)
                    .help(String(localized: "Copy create PR link", table: "GitBranch"))
                }

                HStack(spacing: 8) {
                    Label(String(localized: "Review / Notifications", table: "GitBranch"), systemImage: "bell.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        links.reviewRequestsURL.openInBrowser()
                    } label: {
                        Text(String(localized: "Review Requests", table: "GitBranch"))
                    }
                    .help(String(localized: "Open PR review requests for current account on \(links.provider.rawValue)", table: "GitBranch"))

                    Button {
                        links.commentsURL.openInBrowser()
                    } label: {
                        Text(String(localized: "Comments", table: "GitBranch"))
                    }
                    .help(String(localized: "Open PR comments or activity filter page", table: "GitBranch"))

                    Button {
                        links.notificationsURL.openInBrowser()
                    } label: {
                        Text(String(localized: "Notifications", table: "GitBranch"))
                    }
                    .help(String(localized: "Open \(links.provider.rawValue) PR notifications or activity page", table: "GitBranch"))
                }

                Text(String(localized: "Unread status requires platform account/API authorization; current entries will redirect to the hosting platform's notification, review, and comment filter pages.", table: "GitBranch"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            Text(String(localized: "The current remote does not support generating Pull Request links.", table: "GitBranch"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var rebaseControlView: some View {
        Group {
            if rebaseStatus.isRebasing {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Rebase in progress", table: "GitBranch"))
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
                        Button(String(localized: "Continue Rebase", table: "GitBranch")) {
                            continueRebase()
                        }
                        .disabled(isRebaseActionRunning)

                        Button(String(localized: "Abort Rebase", table: "GitBranch"), role: .destructive) {
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
                    Text(String(localized: "Cherry-pick in progress", table: "GitBranch"))
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let commitHash = cherryPickStatus.commitHash {
                        Text(String(commitHash.prefix(8)))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Button(String(localized: "Continue Cherry-pick", table: "GitBranch")) {
                            continueCherryPick()
                        }
                        .disabled(isCherryPickActionRunning)

                        Button(String(localized: "Abort Cherry-pick", table: "GitBranch"), role: .destructive) {
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
                        String(localized: "Created and switched to branch: %@", table: "GitBranch"),
                        branchName
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    os_log(.error, "❌ Failed to create branch: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "Failed to create branch: %@", table: "GitBranch"),
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
                        String(localized: "Switched to branch: %@", table: "GitBranch"),
                        branch.name
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 切换分支失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "Failed to switch branch: %@", table: "GitBranch"),
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
            alert_error(String(localized: "Cannot delete the current branch", table: "GitBranch"))
            return
        }

        Task.detached {
            do {
                try project.deleteLocalBranch(branch)

                await MainActor.run {
                    let msg = String.localizedStringWithFormat(
                        String(localized: "Branch deleted: %@", table: "GitBranch"),
                        branch.name
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 删除分支失败: \(error.localizedDescription)")
                    let msg = String.localizedStringWithFormat(
                        String(localized: "Failed to delete branch: %@", table: "GitBranch"),
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
                    let msg = String.localizedStringWithFormat(
                        String(localized: "Branch renamed: %@ -> %@", table: "GitBranch"),
                        branch.name, newName
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 重命名分支失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to rename branch: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Branch published: %@", table: "GitBranch"),
                        branch.name
                    ))
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 发布分支失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to publish branch: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Upstream set: %@ -> %@", table: "GitBranch"),
                        branch.name, upstreamBranch
                    ))
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 设置 upstream 失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to set upstream: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Upstream unset for branch: %@", table: "GitBranch"),
                        branch.name
                    ))
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 取消 upstream 失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to unset upstream: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
                }
            }
        }
    }

    private func deleteRemoteBranch(_ branchName: String) {
        guard let project = project else { return }
        let parts = branchName.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            alert_error(String(localized: "Invalid remote branch format", table: "GitBranch"))
            return
        }

        Task.detached {
            do {
                try project.deleteRemoteBranch(named: parts[1], remote: parts[0])

                await MainActor.run {
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Remote branch deleted: %@", table: "GitBranch"),
                        branchName
                    ))
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 删除远程分支失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to delete remote branch: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
        alert_info(String(localized: "PR link copied", table: "GitBranch"))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Merged %@ into %@", table: "GitBranch"),
                        head.name, base.name
                    ))
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 分支比较合并失败: \(error.localizedDescription)")
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Branch merge failed: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Rebased %@ onto %@", table: "GitBranch"),
                        head.name, base.name
                    ))
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
                        alert_error(String(localized: "Rebase encountered conflicts. Please resolve and stage the files before continuing.", table: "GitBranch"))
                    } else {
                        alert_error(String.localizedStringWithFormat(
                            String(localized: "Rebase failed: %@", table: "GitBranch"),
                            error.localizedDescription
                        ))
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
                    alert_info(status.isRebasing ? String(localized: "Rebase continued, steps remaining", table: "GitBranch") : String(localized: "Rebase completed", table: "GitBranch"))
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
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to continue rebase: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String(localized: "Rebase aborted", table: "GitBranch"))
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    self.isRebaseActionRunning = false
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to abort rebase: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String.localizedStringWithFormat(
                        String(localized: "Cherry-picked %d commits into %@", table: "GitBranch"),
                        commitHashes.count, base.name
                    ))
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
                        alert_error(String(localized: "Cherry-pick encountered conflicts. Please resolve and stage the files before continuing.", table: "GitBranch"))
                    } else {
                        alert_error(String.localizedStringWithFormat(
                            String(localized: "Cherry-pick failed: %@", table: "GitBranch"),
                            error.localizedDescription
                        ))
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
                    alert_info(status.isCherryPicking ? String(localized: "Cherry-pick continued, commits remaining", table: "GitBranch") : String(localized: "Cherry-pick completed", table: "GitBranch"))
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
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to continue cherry-pick: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                    alert_info(String(localized: "Cherry-pick aborted", table: "GitBranch"))
                    self.loadBranches()
                    self.loadCompare()
                }
            } catch {
                await MainActor.run {
                    self.isCherryPickActionRunning = false
                    alert_error(String.localizedStringWithFormat(
                        String(localized: "Failed to abort cherry-pick: %@", table: "GitBranch"),
                        error.localizedDescription
                    ))
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
                        String(localized: "Failed to load branch list: %@", table: "GitBranch"),
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
