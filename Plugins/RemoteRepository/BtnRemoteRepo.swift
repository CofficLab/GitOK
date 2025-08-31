import MagicCore
import OSLog
import SwiftUI

/// 远程仓库管理按钮视图
/// 提供一个按钮来打开远程仓库管理界面
struct BtnRemoteRepositoryView: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var showRemoteManagement = false
    @State private var isGitProject = false
    @State private var hovered = false

    static let shared = BtnRemoteRepositoryView()

    init() {}

    var body: some View {
        ZStack {
            if data.project != nil, isGitProject {
                HStack {
                    Image(systemName: .iconGlobe)
                }
                .help("管理远程仓库")
                .onTapGesture {
                    showRemoteManagement = true
                }
                .onHover(perform: { hovering in
                    hovered = hovering
                })
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 0))
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

        isGitProject = project.isGit()
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

#Preview("Button Remote Repository View") {
    BtnRemoteRepositoryView()
        .inRootView()
}
