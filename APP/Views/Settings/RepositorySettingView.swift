import Foundation
import GitOKUI
import LibGit2Swift
import MagicKit
import OSLog
import ProjectRulesKit
import SwiftUI

/// 仓库设置视图
struct RepositorySettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📁"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 当前项目的远程仓库列表
    @State private var remotes: [GitRemote] = []

    /// 是否正在加载
    @State private var isLoading = false

    /// 是否显示添加远程仓库表单
    @State private var showAddRemoteSheet = false

    /// 错误消息
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 当前项目信息
                if let project = vm.project {
                    currentProjectInfo(project: project)

                    // 远程仓库列表
                    if !remotes.isEmpty {
                        remoteRepositoryList
                    } else {
                        emptyRemoteRepositoryState
                    }

                    // 添加远程仓库按钮
                    addRemoteRepositoryButton
                } else {
                    noProjectSelected
                }

                // 错误消息
                if let errorMessage = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: .iconWarning)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle(Text("仓库设置", tableName: "Core"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    // 关闭设置视图（通过通知）
                    NotificationCenter.default.post(name: .didUpdateRemoteRepository, object: nil)
                }) {
                    Text("完成", tableName: "Core")
                }
            }
        }
        .onAppear(perform: loadData)
        .sheet(isPresented: $showAddRemoteSheet) {
            AddRemoteRepositorySheet { name, url in
                addRemoteRepository(name: name, url: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateRemoteRepository)) { _ in
            loadData()
        }
        .onProjectGitRefsDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadData()
        }
    }

    // MARK: - View Components

    /// 当前项目信息
    private func currentProjectInfo(project: Project) -> some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Current Project", table: "Core")) {
            VStack(spacing: 0) {
                repositoryInfoRow(
                    title: String(localized: "Project Name", table: "Core"),
                    description: project.title,
                    icon: "folder"
                )

                Divider()

                repositoryInfoRow(
                    title: String(localized: "Local Path", table: "Core"),
                    description: project.path,
                    icon: "line.3.horizontal.decrease.circle"
                ) {
                    Image.finder.inButtonWithAction {
                        project.url.openFolder()
                    }
                }
            }
        }
    }

    /// 远程仓库列表
    private var remoteRepositoryList: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Remote Repository", table: "Core")) {
            VStack(spacing: 0) {
                ForEach(remotes) { remote in
                    remoteRepositoryRow(remote)
                    if remote.id != remotes.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    /// 单个远程仓库行
    private func remoteRepositoryRow(_ remote: GitRemote) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 8) {
                Image(systemName: "cloud")
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(remote.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(remote.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // 在浏览器中打开（如果是 HTTPS）
                if let httpsURL = RemoteRepositoryFormRules.remoteWebLink(for: remote.url)?.url {
                    Image.safari.inButtonWithAction {
                        httpsURL.openInBrowser()
                    }
                }

                // 复制 URL
                Image.copyIcon.inButtonWithAction {
                    remote.url.copy()
                }

                // 删除按钮
                Image.trash.inButtonWithAction {
                    deleteRemoteRepository(remote)
                }
            }
        }
    }

    /// 空状态提示
    private var emptyRemoteRepositoryState: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Remote Repository", table: "Core")) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: .iconCloud)
                        .foregroundColor(.secondary)
                    Text(String(localized: "No Remote Repository Configured", table: "Core"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()

                Text(String(localized: "Add a remote repository to enable push and pull operations", table: "Core"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// 添加远程仓库按钮
    private var addRemoteRepositoryButton: some View {
        GitOKUI.AppSettingsSection {
            repositoryInfoRow(
                title: String(localized: "Add Remote Repository", table: "Core"),
                description: String(localized: "Add a new remote repository URL", table: "Core"),
                icon: "plus"
            )
            .contentShape(Rectangle())
            .onTapGesture {
                showAddRemoteSheet = true
            }
        }
    }

    /// 没有选中项目
    private var noProjectSelected: some View {
        GitOKUI.AppSettingsSection {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text(String(localized: "Please Select a Project First", table: "Core"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func repositoryInfoRow<Accessory: View>(
        title: String,
        description: String,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                accessory()
            }
        }
    }

    private func repositoryInfoRow(
        title: String,
        description: String,
        icon: String
    ) -> some View {
        repositoryInfoRow(title: title, description: description, icon: icon) {
            EmptyView()
        }
    }

    // MARK: - Actions

    /// 添加远程仓库
    private func addRemoteRepository(name: String, url: String) {
        guard let project = vm.project else {
        errorMessage = String(localized: "Please Select a Project First", table: "Core")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try project.addRemote(name: name, url: url)

            if Self.verbose {
                os_log("\(Self.t)✅ Added remote: \(name)")
            }

            // 重新加载列表
            loadData()
        } catch {
            isLoading = false
        errorMessage = String.localizedStringWithFormat(String(localized: "Failed to add remote repository: %@", table: "Core"), error.localizedDescription)

            if Self.verbose {
                os_log(.error, "\(Self.t)❌ Failed to add remote: \(error)")
            }
        }

        isLoading = false
    }

    /// 删除远程仓库
    private func deleteRemoteRepository(_ remote: GitRemote) {
        guard let project = vm.project else { return }

        isLoading = true
        errorMessage = nil

        do {
            try project.removeRemote(name: remote.name)

            if Self.verbose {
                os_log("\(Self.t)✅ Removed remote: \(remote.name)")
            }

            // 重新加载列表
            loadData()
        } catch {
            isLoading = false
        errorMessage = String.localizedStringWithFormat(String(localized: "Failed to remove remote repository: %@", table: "Core"), error.localizedDescription)

            if Self.verbose {
                os_log(.error, "\(Self.t)❌ Failed to remove remote: \(error)")
            }
        }

        isLoading = false
    }

    // MARK: - Load Data

    private func loadData() {
        guard let project = vm.project else {
            remotes = []
            return
        }

        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let remoteList = try project.remoteList()

                await MainActor.run {
                    self.remotes = remoteList
                    self.isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)Loaded \(remoteList.count) remotes")
                    }
                }
            } catch {
                await MainActor.run {
                    self.remotes = []
                    self.isLoading = false
                    self.errorMessage = String.localizedStringWithFormat(String(localized: "Failed to load remote repository: %@", table: "Core"), error.localizedDescription)

                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to load remotes: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

}

// MARK: - Add Remote Repository Sheet

struct AddRemoteRepositorySheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var remoteName: String = "origin"
    @State private var remoteURL: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onAdd: (String, String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Remote Repository Information", tableName: "Core")) {
                    TextField(String(localized: "Name", table: "Core"), text: $remoteName)
                        .textFieldStyle(.plain)

                    TextField(String(localized: "URL", table: "Core"), text: $remoteURL)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                }

                if let errorMessage = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: .iconWarning)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Add Remote Repository", tableName: "Core"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel", tableName: "Core")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        addRemote()
                    }) {
                        Text("Add", tableName: "Core")
                    }
                    .disabled(!RemoteRepositoryFormRules.isFormValid(name: remoteName, url: remoteURL) || isLoading)
                }
            }
        }
        .frame(width: 500, height: 300)
    }

    private func addRemote() {
        let input = RemoteRepositoryFormRules.normalizedInput(name: remoteName, url: remoteURL)
        guard RemoteRepositoryFormRules.isFormValid(name: input.name, url: input.url) else { return }

        isLoading = true

        Task {
            // 简单验证
            if !isValidGitURL(input.url) {
                await MainActor.run {
                    isLoading = false
                    errorMessage = String(localized: "Please enter a valid Git URL", table: "Core")
                }
                return
            }

            await MainActor.run {
                onAdd(input.name, input.url)
                dismiss()
            }
        }
    }

    private func isValidGitURL(_ url: String) -> Bool {
        // 简单的 URL 验证
        return url.contains("/") || url.contains("@")
    }
}
