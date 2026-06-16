import GitOKAppCore
import GitOKUI
import GitOKSupportKit
import SwiftUI

public struct NoRepositoriesGuideView: View {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var showCreateRepositorySheet = false

    public var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            VStack(spacing: 14) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 66, weight: .regular))
                    .foregroundStyle(.secondary)

                Text("开始使用 GitOK")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("添加已有仓库，或新建一个本地仓库。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            HStack(spacing: 12) {
                AppButton("添加项目", systemImage: "folder", style: .primary) {
                    openExistingProject()
                }

                AppButton("新建仓库", systemImage: "plus.square.on.square") {
                    showCreateRepositorySheet = true
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                guideTip("添加项目会把本地已有 Git 仓库加入列表。")
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
