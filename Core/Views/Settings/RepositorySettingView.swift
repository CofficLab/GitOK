import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 仓库设置视图
struct RepositorySettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📁"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider
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
    }

    // MARK: - View Components

    /// 当前项目信息
    private func currentProjectInfo(project: Project) -> some View {
        MagicSettingSection(title: String(localized: "当前项目", table: "Core"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                MagicSettingRow(
                    title: String(localized: "项目名称", table: "Core"),
                    description: project.title,
                    icon: .iconFolder
                ) {
                    EmptyView()
                }

                Divider()

                MagicSettingRow(
                    title: String(localized: "本地路径", table: "Core"),
                    description: project.path,
                    icon: .iconFilter
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
        MagicSettingSection(title: String(localized: "远程仓库", table: "Core"), titleAlignment: .leading) {
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
        MagicSettingRow(
            title: remote.name,
            description: remote.url,
            icon: .iconCloud
        ) {
            HStack(spacing: 8) {
                // 在浏览器中打开（如果是 HTTPS）
                if let httpsURL = convertToHTTPSURL(remote.url) {
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
        MagicSettingSection(title: String(localized: "远程仓库", table: "Core"), titleAlignment: .leading) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: .iconCloud)
                        .foregroundColor(.secondary)
                    Text(String(localized: "未配置远程仓库", table: "Core"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()

                Text(String(localized: "添加远程仓库以便进行推送和拉取操作", table: "Core"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// 添加远程仓库按钮
    private var addRemoteRepositoryButton: some View {
        MagicSettingSection(title: "", titleAlignment: .leading) {
            MagicSettingRow(
                title: String(localized: "添加远程仓库", table: "Core"),
                description: String(localized: "添加新的远程仓库地址", table: "Core"),
                icon: .iconPlus
            ) {
                EmptyView()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showAddRemoteSheet = true
            }
        }
    }

    /// 没有选中项目
    private var noProjectSelected: some View {
        MagicSettingSection(title: "", titleAlignment: .leading) {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text(String(localized: "请先选择一个项目", table: "Core"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    // MARK: - Actions

    /// 添加远程仓库
    private func addRemoteRepository(name: String, url: String) {
        guard let project = vm.project else {
        errorMessage = String(localized: "请先选择一个项目", table: "Core")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try LibGit2.addRemote(name: name, url: url, at: project.path)

            if Self.verbose {
                os_log("\(Self.t)✅ Added remote: \(name)")
            }

            // 重新加载列表
            loadData()

            // 发送通知
            NotificationCenter.default.post(name: .didUpdateRemoteRepository, object: nil)
        } catch {
            isLoading = false
        errorMessage = String.localizedStringWithFormat(String(localized: "添加远程仓库失败: %@", table: "Core"), error.localizedDescription)

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
            try LibGit2.removeRemote(name: remote.name, at: project.path)

            if Self.verbose {
                os_log("\(Self.t)✅ Removed remote: \(remote.name)")
            }

            // 重新加载列表
            loadData()

            // 发送通知
            NotificationCenter.default.post(name: .didUpdateRemoteRepository, object: nil)
        } catch {
            isLoading = false
        errorMessage = String.localizedStringWithFormat(String(localized: "删除远程仓库失败: %@", table: "Core"), error.localizedDescription)

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
                    self.errorMessage = String.localizedStringWithFormat(String(localized: "加载远程仓库失败: %@", table: "Core"), error.localizedDescription)

                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to load remotes: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// 将 Git URL 转换为 HTTPS URL
    private func convertToHTTPSURL(_ gitURL: String) -> URL? {
        var formatted = gitURL

        if formatted.hasPrefix("git@") {
            formatted = formatted.replacingOccurrences(of: ":", with: "/")
            formatted = formatted.replacingOccurrences(of: "git@", with: "https://")
        } else if formatted.hasPrefix("ssh://") {
            formatted = formatted.replacingOccurrences(of: "ssh://git@", with: "https://")
        } else if formatted.hasPrefix("git://") {
            formatted = formatted.replacingOccurrences(of: "git://", with: "https://")
        }

        return URL(string: formatted)
    }
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
                Section(header: Text("远程仓库信息", tableName: "Core")) {
                    TextField(String(localized: "名称", table: "Core"), text: $remoteName)
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
            .navigationTitle(Text("添加远程仓库", tableName: "Core"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消", tableName: "Core")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        addRemote()
                    }) {
                        Text("添加", tableName: "Core")
                    }
                    .disabled(remoteName.isEmpty || remoteURL.isEmpty || isLoading)
                }
            }
        }
        .frame(width: 500, height: 300)
    }

    private func addRemote() {
        guard !remoteName.isEmpty, !remoteURL.isEmpty else { return }

        isLoading = true

        Task {
            // 简单验证
            if !isValidGitURL(remoteURL) {
                await MainActor.run {
                    isLoading = false
                    errorMessage = String(localized: "请输入有效的 Git URL", table: "Core")
                }
                return
            }

            await MainActor.run {
                onAdd(remoteName, remoteURL)
                dismiss()
            }
        }
    }

    private func isValidGitURL(_ url: String) -> Bool {
        // 简单的 URL 验证
        return url.contains("/") || url.contains("@")
    }
}
