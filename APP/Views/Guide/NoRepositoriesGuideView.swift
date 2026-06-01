import GitOKUI
import MagicKit
import PluginGitClone
import SwiftUI

struct NoRepositoriesGuideView: View {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var showCreateRepositorySheet = false
    @State private var showCloneRepositorySheet = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            VStack(spacing: 14) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 66, weight: .regular))
                    .foregroundStyle(.secondary)

                Text("开始使用 GitOK")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("添加已有仓库，或从远程 Clone / 新建一个仓库。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            HStack(spacing: 12) {
                AppButton("添加项目", systemImage: "folder", style: .primary) {
                    openExistingProject()
                }

                AppButton("Clone", systemImage: "square.and.arrow.down") {
                    showCloneRepositorySheet = true
                }

                AppButton("新建仓库", systemImage: "plus.square.on.square") {
                    showCreateRepositorySheet = true
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                guideTip("添加项目会把本地已有 Git 仓库加入列表。")
                guideTip("Clone 会从远程地址下载仓库并自动加入项目。")
                guideTip("新建仓库会创建本地 Git 仓库和初始提交。")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showCreateRepositorySheet) {
            CreateRepositorySheet()
        }
        .sheet(isPresented: $showCloneRepositorySheet) {
            PluginGitClone.CloneRepositorySheet(context: GitClonePluginContextFactory.make(data: data, projectVM: vm))
        }
    }

    private func guideTip(_ text: LocalizedStringKey) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .labelStyle(.titleAndIcon)
    }

    private func openExistingProject() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        if let project = data.addProject(url: url, using: data.repoManager.projectRepo) {
            vm.setProject(project, reason: "NoRepositoriesGuide")
        }
    }
}

#Preview("No Repositories") {
    NoRepositoriesGuideView()
        .inRootView()
        .frame(width: 800, height: 600)
}
