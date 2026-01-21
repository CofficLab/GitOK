import MagicKit
import OSLog
import SwiftUI

/// 远程仓库管理按钮视图
/// 提供一个按钮来打开远程仓库管理界面
struct BtnRemoteRepositoryView: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var showRemoteManagement = false
    @State private var isGitProject = false

    static let shared = BtnRemoteRepositoryView()

    init() {}

    var body: some View {
        ZStack {
            if data.project != nil, isGitProject {
                StatusBarTile(icon: .iconGlobe, onTap: {
                    showRemoteManagement = true
                }) {
                    EmptyView()
                }
                .help("管理远程仓库")
            }
        }
        .sheet(isPresented: $showRemoteManagement) {
            RemoteRepositoryView()
                .environmentObject(data)
        }
        .onAppear(perform: {
            Task {
                await self.updateIsGitProjectAsync()
            }
        })
        .onChange(of: data.project) {
            Task {
                await self.updateIsGitProjectAsync()
            }
        }
    }
}

// MARK: - Actions

extension BtnRemoteRepositoryView {
    private func updateIsGitProject() {
        guard let project = data.project else {
            isGitProject = false
            return
        }

        isGitProject = project.isGitRepo
    }
    
    /**
        异步更新Git项目状态
        
        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
    private func updateIsGitProjectAsync() async {
        guard let project = data.project else {
            await MainActor.run {
                self.isGitProject = false
            }
            return
        }
        
        let isGit = await project.isGitAsync()
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(RemoteRepositoryPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(RemoteRepositoryPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
