import Foundation
import GitCoreKit
import GitOKUI
import GitOKSupportKit
import OSLog
import ProjectRulesKit
import SwiftUI

private enum RepositorySettingBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

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
                    AppErrorBanner(message: errorMessage)
                }
            }
            .padding()
        }
        .navigationTitle(Text("仓库设置"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton("完成", style: .secondary, size: .small) {
                    // 关闭设置视图（通过通知）
                    NotificationCenter.default.post(name: .didUpdateRemoteRepository, object: nil)
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
        GitOKUI.AppSettingsSection(title: String(localized: "Current Project")) {
            VStack(spacing: 0) {
                repositoryInfoRow(
                    title: String(localized: "Project Name"),
                    description: project.title,
                    icon: "folder"
                )

                Divider()

                repositoryInfoRow(
                    title: String(localized: "Local Path"),
                    description: project.path,
                    icon: "line.3.horizontal.decrease.circle"
                ) {
                    AppIconButton(systemImage: "folder", size: .regular) {
                        project.url.openFolder()
                    }
                }
            }
        }
    }

    /// 远程仓库列表
    private var remoteRepositoryList: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Remote Repository")) {
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
                    AppIconButton(systemImage: "safari", size: .regular) {
                        httpsURL.openInBrowser()
                    }
                }

                // 复制 URL
                AppIconButton(systemImage: "doc.on.doc", size: .regular) {
                    remote.url.copy()
                }

                // 删除按钮
                AppIconButton(systemImage: "trash", tint: .red, size: .regular) {
                    deleteRemoteRepository(remote)
                }
            }
        }
    }

    /// 空状态提示
    private var emptyRemoteRepositoryState: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Remote Repository")) {
            AppEmptyState(
                icon: .iconCloud,
                title: String(localized: "No Remote Repository Configured"),
                description: String(localized: "Add a remote repository to enable push and pull operations")
            )
            .frame(minHeight: 160)
        }
    }

    /// 添加远程仓库按钮
    private var addRemoteRepositoryButton: some View {
        GitOKUI.AppSettingsSection {
            repositoryInfoRow(
                title: String(localized: "Add Remote Repository"),
                description: String(localized: "Add a new remote repository URL"),
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
            AppEmptyState(
                icon: "folder.badge.questionmark",
                title: String(localized: "Please Select a Project First")
            )
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
        guard let loadedProject = vm.project else {
            errorMessage = String(localized: "Please Select a Project First")
            return
        }
        let projectTransfer = RepositorySettingBackgroundRunner.UnsafeTransfer(value: loadedProject)

        isLoading = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                try await projectTransfer.value.addRemoteAsync(name: name, url: url)
                let remoteList = try await projectTransfer.value.remoteListAsync()

                Task { @MainActor in
                    remotes = remoteList
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)✅ Added remote: \(name)")
                    }
                }
            } catch {
                let message = String.localizedStringWithFormat(
                    String(localized: "Failed to add remote repository: %@"),
                    error.localizedDescription
                )

                Task { @MainActor in
                    isLoading = false
                    errorMessage = message

                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to add remote: \(message)")
                    }
                }
            }
        }
    }

    /// 删除远程仓库
    private func deleteRemoteRepository(_ remote: GitRemote) {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = RepositorySettingBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let remoteName = remote.name

        isLoading = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                try await projectTransfer.value.removeRemoteAsync(name: remoteName)
                let remoteList = try await projectTransfer.value.remoteListAsync()

                Task { @MainActor in
                    remotes = remoteList
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)✅ Removed remote: \(remoteName)")
                    }
                }
            } catch {
                let message = String.localizedStringWithFormat(
                    String(localized: "Failed to remove remote repository: %@"),
                    error.localizedDescription
                )

                Task { @MainActor in
                    isLoading = false
                    errorMessage = message

                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to remove remote: \(message)")
                    }
                }
            }
        }
    }

    // MARK: - Load Data

    private func loadData() {
        guard let loadedProject = vm.project else {
            remotes = []
            return
        }
        let projectTransfer = RepositorySettingBackgroundRunner.UnsafeTransfer(value: loadedProject)

        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let remoteList = try await projectTransfer.value.remoteListAsync()

                Task { @MainActor in
                    remotes = remoteList
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)Loaded \(remoteList.count) remotes")
                    }
                }
            } catch {
                let message = String.localizedStringWithFormat(
                    String(localized: "Failed to load remote repository: %@"),
                    error.localizedDescription
                )

                Task { @MainActor in
                    remotes = []
                    isLoading = false
                    errorMessage = message

                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to load remotes: \(message)")
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
                Section(header: Text("Remote Repository Information")) {
                    AppInputField(String(localized: "Name"), text: $remoteName)

                    AppInputField(String(localized: "URL"), text: $remoteURL)
                        .disableAutocorrection(true)
                }

                if let errorMessage = errorMessage {
                    Section {
                        AppErrorBanner(message: errorMessage)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Add Remote Repository"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AppButton("Cancel", style: .secondary, size: .small) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    AppButton("Add", systemImage: "plus", style: .secondary, size: .small, isLoading: isLoading) {
                        addRemote()
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
                    errorMessage = String(localized: "Please enter a valid Git URL")
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
