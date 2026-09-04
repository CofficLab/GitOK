import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 工具栏右上角分支选择器：显示当前分支名，点击弹出菜单切换分支。
///
/// 找回 v3.0.22 `GitBranchPlugin.toolbarTrailingItems` 提供的 `BranchPickerView`：
/// - 图标 + 当前分支名常驻工具栏右侧；
/// - 点击展开分支菜单，当前分支打勾，点击其他分支执行 checkout 切换；
/// - 无项目 / 非 git 仓库时显示 "No Branch"。
public struct BranchPickerView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var branches: [GitBranchSummary] = []
    @State private var currentBranch: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if let currentBranch, !currentBranch.isEmpty {
                Menu {
                    if branches.isEmpty {
                        Text("No Branch")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(branches) { branch in
                            Button {
                                checkout(branch)
                            } label: {
                                HStack {
                                    Text(branch.name)
                                    if branch.name == currentBranch {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Text(currentBranch)
                        .font(.appCaption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .disabled(branches.isEmpty)
            } else {
                Text("No Branch")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize()
        .onAppear { load() }
        .onReceive(observation.$revision) { _ in load() }
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                load()
            }
        }
        .help(errorMessage ?? "Switch Branch")
    }

    @MainActor
    private func load() {
        guard let url = projects.currentProject?.url else {
            branches = []
            currentBranch = nil
            errorMessage = nil
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .utility) {
            do {
                let loaded = try GitBranchOperation.listBranches(in: url)
                let current = GitRefReader.currentBranch(in: url)
                await MainActor.run {
                    branches = loaded
                    currentBranch = current
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    branches = []
                    currentBranch = nil
                    isLoading = false
                }
            }
        }
    }

    @MainActor
    private func checkout(_ branch: GitBranchSummary) {
        guard let url = projects.currentProject?.url else { return }
        let branchName = branch.name
        errorMessage = nil
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                try GitBranchOperation.checkoutBranch(named: branchName, in: url)
                await MainActor.run {
                    isLoading = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
