import MagicKit
import LibGit2Swift
import MagicAlert
import SwiftUI
import OSLog

/// 远程仓库管理视图
/// 用于展示、添加、编辑和删除Git远程仓库
struct RemoteRepositoryView: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var remotes: [GitRemote] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddRemoteSheet = false
    @State private var selectedRemote: GitRemote?
    @State private var showEditRemoteSheet = false
    @State private var editingRemote: GitRemote?
    
    private let verbose = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("远程仓库管理")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("关闭")
                }
                
                Text("管理当前项目的Git远程仓库配置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Main content
            VStack(spacing: 20) {
                // Remote List
                Group {
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else if remotes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "externaldrive.badge.wifi")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("暂无远程仓库")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("点击下方按钮添加第一个远程仓库")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(remotes) { remote in
                                    RemoteRepositoryRowView(
                                        remote: remote,
                                        selectedRemote: selectedRemote,
                                        onSelect: { selectedRemote in
                                            self.selectedRemote = selectedRemote
                                        },
                                        onEdit: { remote in
                                            editRemote(remote)
                                        },
                                        onDelete: { remote in
                                            deleteRemote(remote)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Error Message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("清除") {
                            self.errorMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button("添加远程仓库") {
                    showAddRemoteSheet = true
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showAddRemoteSheet) {
            AddRemoteSheet(onAdd: { name, url in
                addRemote(name: name, url: url)
            })
        }
        .sheet(isPresented: $showEditRemoteSheet) {
            if let editingRemote = editingRemote {
                EditRemoteSheet(
                    remote: editingRemote,
                    onSave: { name, url in
                        updateRemote(originalName: editingRemote.name, newName: name, newURL: url)
                    }
                )
            }
        }
        .onAppear(perform: loadRemotes)
        .disabled(isLoading)
    }
}

// MARK: - Actions

extension RemoteRepositoryView {
    private func loadRemotes() {
        guard let project = vm.project else {
            errorMessage = "没有选择项目"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            remotes = try project.remoteList()
            
            if verbose {
                os_log("\(self.t)✅ Loaded \(remotes.count) remotes")
            }
        } catch {
            errorMessage = "加载远程仓库失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to load remotes: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func addRemote(name: String, url: String) {
        guard let project = vm.project else {
            errorMessage = "没有选择项目"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try LibGit2.addRemote(name: name, url: url, at: project.path)
            loadRemotes() // 重新加载列表

            if verbose {
                os_log("\(self.t)✅ Added remote: \(name) -> \(url)")
            }
        } catch {
            errorMessage = "添加远程仓库失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to add remote: \(error)")
            }
        }

        isLoading = false
    }
    
    private func editRemote(_ remote: GitRemote) {
        editingRemote = remote
        showEditRemoteSheet = true
        
        if verbose {
            os_log("\(self.t)📝 Edit remote: \(remote.name)")
        }
    }
    
    private func updateRemote(originalName: String, newName: String, newURL: String) {
        guard let project = vm.project else {
            errorMessage = "没有选择项目"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 先删除旧的远程仓库，再添加新的
            try LibGit2.removeRemote(name: originalName, at: project.path)
            try LibGit2.addRemote(name: newName, url: newURL, at: project.path)

            loadRemotes() // 重新加载列表

            if verbose {
                os_log("\(self.t)✅ Updated remote: \(originalName) -> \(newName): \(newURL)")
            }
        } catch {
            errorMessage = "更新远程仓库失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to update remote: \(error)")
            }
        }

        isLoading = false
    }
    
    private func deleteRemote(_ remote: GitRemote) {
        guard let project = vm.project else {
            errorMessage = "没有选择项目"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try LibGit2.removeRemote(name: remote.name, at: project.path)
            loadRemotes() // 重新加载列表

            if selectedRemote?.id == remote.id {
                selectedRemote = nil
            }

            if verbose {
                os_log("\(self.t)✅ Removed remote: \(remote.name)")
            }
        } catch {
            errorMessage = "删除远程仓库失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to remove remote: \(error)")
            }
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview("Remote Repository View") {
    RemoteRepositoryView()
        .inRootView()
        .inMagicContainer()
}
