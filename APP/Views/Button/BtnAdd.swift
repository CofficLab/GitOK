import GitOKSupportKit
import OSLog
import SwiftUI

/// 添加项目按钮组件
struct BtnAdd: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "➕"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 数据提供者环境对象
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var showCreateRepositorySheet = false
    @State private var showCloneRepositorySheet = false

    /// 按钮视图主体
    var body: some View {
        Menu {
            Button {
                open()
            } label: {
                Label("添加现有项目", systemImage: "folder")
            }

            Button {
                showCreateRepositorySheet = true
            } label: {
                Label("新建仓库", systemImage: "plus.square.on.square")
            }

            Button {
                showCloneRepositorySheet = true
            } label: {
                Label(GitCloneLocalization.string("Clone Repository"), systemImage: "square.and.arrow.down")
            }
        } label: {
            Label("添加项目", systemImage: "plus")
        }
        .sheet(isPresented: $showCreateRepositorySheet) {
            CreateRepositorySheet()
        }
        .sheet(isPresented: $showCloneRepositorySheet) {
            let handlers = PluginRepositoryContextFactory.handlers(data: g, projectVM: vm)
            CloneRepositorySheet(
                projectExists: handlers.onProjectExists,
                onCloneCompleted: handlers.onRepositoryImported,
                setActivityStatus: handlers.onActivityStatusUpdate,
                onCloneSucceeded: handlers.onInfoMessage
            )
        }
    }

    /// 打开文件选择面板
    private func open() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            addURL(url)
        } else {
        }
    }

    /// 添加项目URL
    /// - Parameter url: 项目目录URL
    private func addURL(_ url: URL) {
        _ = withAnimation {
            g.addProject(url: url, using: g.repoManager.projectRepo)
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
