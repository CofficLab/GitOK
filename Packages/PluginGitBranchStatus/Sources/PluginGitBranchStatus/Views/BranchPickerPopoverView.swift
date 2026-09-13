import KitGit
import ProviderProjects
import ProviderGit
import SwiftUI

/// 工具栏分支选择弹层：搜索 + 新建分支 + 本地 / 远程分支列表。
///
/// 结构与样式对齐工具栏中部的项目管理弹层 `ProjectToolbarPopoverView`：
/// - header 为搜索框 + 新建分支按钮（+），点击后展开内嵌输入行，回车创建并切换；
/// - 本地分支列表当前分支高亮打勾，点击其他分支执行 checkout 并关闭弹层；
/// - 点击远程分支会创建对应的本地跟踪分支并切换过去；
/// - 无项目 / 加载失败时显示空状态。
struct BranchPickerPopoverView: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    let viewModel: GitBranchStatusViewModel
    /// 切换 / 新建成功后由本视图置为 false，关闭工具栏按钮的弹层。
    let isPresented: Binding<Bool>
    @StateObject private var observation: ProjectObservationModel
    @State private var branches: [GitBranchSummary] = []
    @State private var searchText = ""
    @State private var isCreatingNew = false
    @State private var newBranchName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadGeneration = 0
    @State private var projectGeneration = 0
    @State private var loadTask: Task<Void, Never>?
    @FocusState private var isNewBranchFieldFocused: Bool

    init(
        projects: any ProjectProviding,
        git: any GitProviding,
        viewModel: GitBranchStatusViewModel,
        isPresented: Binding<Bool>
    ) {
        self.projects = projects
        self.git = git
        self.viewModel = viewModel
        self.isPresented = isPresented
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    private var localBranches: [GitBranchSummary] {
        BranchLogic.filter(branches: branches.filter { !$0.isRemote }, query: searchText)
    }

    private var remoteBranches: [GitBranchSummary] {
        BranchLogic.filter(branches: branches.filter { $0.isRemote }, query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if isCreatingNew {
                newBranchInput
            }
            Divider()
            listContent
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 320)
        .frame(minHeight: 220, maxHeight: 420)
        .onAppear(perform: load)
        .onReceive(observation.$lastEvent) { event in
            switch event {
            case .selectionChanged:
                projectGeneration += 1
                branches = []
                errorMessage = nil
                isLoading = false
                load()
            case .dataChanged:
                load()
            default:
                break
            }
        }
        .onDisappear(perform: cancelLoad)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            TextField(LumiPluginLocalization.string("Search", bundle: .module), text: $searchText)
                .textFieldStyle(.roundedBorder)

            Button {
                if isCreatingNew {
                    isCreatingNew = false
                    newBranchName = ""
                } else {
                    isCreatingNew = true
                    newBranchName = ""
                    isNewBranchFieldFocused = true
                }
            } label: {
                Image(systemName: isCreatingNew ? "xmark" : "plus")
            }
            .buttonStyle(.bordered)
            .help(isCreatingNew ? LumiPluginLocalization.string("Cancel", bundle: .module) : LumiPluginLocalization.string("New Branch", bundle: .module))
            .disabled(isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var newBranchInput: some View {
        HStack(spacing: 8) {
            TextField(LumiPluginLocalization.string("New branch name", bundle: .module), text: $newBranchName)
                .textFieldStyle(.roundedBorder)
                .focused($isNewBranchFieldFocused)
                .onSubmit { createBranch() }

            Button("Create") {
                createBranch()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    // MARK: - List

    @ViewBuilder
    private var listContent: some View {
        if isLoading && branches.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 80)
        } else if branches.isEmpty {
            emptyState(title: LumiPluginLocalization.string("No Branches", bundle: .module), icon: "arrow.triangle.branch")
        } else if localBranches.isEmpty && remoteBranches.isEmpty {
            emptyState(title: LumiPluginLocalization.string("No Results", bundle: .module), icon: "magnifyingglass")
        } else {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(localBranches) { branch in
                        row(for: branch)
                    }
                    if !remoteBranches.isEmpty {
                        if !localBranches.isEmpty {
                            Divider()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                        }
                        remoteSection
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)
        }
    }

    private var remoteSection: some View {
        VStack(spacing: 2) {
            ForEach(remoteBranches) { branch in
                Button {
                    switchRemoteBranch(branch)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "network")
                            .foregroundStyle(.secondary)
                        Text(branch.name)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.down.to.line")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help(LumiPluginLocalization.string("Checkout locally", bundle: .module))
            }
        }
    }

    private func emptyState(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func row(for branch: GitBranchSummary) -> some View {
        let isCurrent = branch.name == viewModel.currentBranch
        return Button {
            switchBranch(branch)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCurrent ? "checkmark.circle.fill" : "arrow.triangle.branch")
                    .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                Text(branch.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    @MainActor
    private func load() {
        loadGeneration += 1
        let generation = loadGeneration
        let requestProjectGeneration = projectGeneration
        loadTask?.cancel()
        loadTask = nil

        guard let url = projects.currentProject?.url else {
            branches = []
            isLoading = false
            errorMessage = nil
            return
        }
        let repositoryURL = url.standardizedFileURL
        isLoading = true
        errorMessage = nil

        loadTask = Task { @MainActor in
            let result = await Task.detached(priority: .utility) {
                Result { try git.listBranches(in: repositoryURL) }
            }.value

            guard !Task.isCancelled,
                  loadGeneration == generation,
                  projectGeneration == requestProjectGeneration,
                  projects.currentProject?.url.standardizedFileURL == repositoryURL
            else { return }

            loadTask = nil
            isLoading = false
            switch result {
            case .success(let loaded):
                branches = loaded
            case .failure(let error):
                branches = []
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func cancelLoad() {
        loadGeneration += 1
        loadTask?.cancel()
        loadTask = nil
    }

    @MainActor
    private func switchBranch(_ branch: GitBranchSummary) {
        guard let url = projects.currentProject?.url, branch.name != viewModel.currentBranch else { return }
        let repositoryURL = url.standardizedFileURL
        let requestProjectGeneration = projectGeneration
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                Result { try git.checkoutBranch(named: branch.name, in: repositoryURL) }
            }.value
            if case .success = result,
               projects.currentProject?.url.standardizedFileURL == repositoryURL {
                projects.notifyDataChanged()
            }
            guard projectGeneration == requestProjectGeneration,
                  projects.currentProject?.url.standardizedFileURL == repositoryURL else { return }
            isLoading = false
            switch result {
            case .success:
                isPresented.wrappedValue = false
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func switchRemoteBranch(_ branch: GitBranchSummary) {
        guard let url = projects.currentProject?.url else { return }
        let repositoryURL = url.standardizedFileURL
        let requestProjectGeneration = projectGeneration
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                Result { try git.checkoutRemoteBranch(named: branch.name, as: nil, in: repositoryURL) }
            }.value
            if case .success = result,
               projects.currentProject?.url.standardizedFileURL == repositoryURL {
                projects.notifyDataChanged()
            }
            guard projectGeneration == requestProjectGeneration,
                  projects.currentProject?.url.standardizedFileURL == repositoryURL else { return }
            isLoading = false
            switch result {
            case .success:
                isPresented.wrappedValue = false
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func createBranch() {
        guard let url = projects.currentProject?.url else { return }
        let repositoryURL = url.standardizedFileURL
        let requestProjectGeneration = projectGeneration
        let name = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    try git.createBranch(named: name, in: repositoryURL)
                    try git.checkoutBranch(named: name, in: repositoryURL)
                }
            }.value
            if case .success = result,
               projects.currentProject?.url.standardizedFileURL == repositoryURL {
                projects.notifyDataChanged()
            }
            guard projectGeneration == requestProjectGeneration,
                  projects.currentProject?.url.standardizedFileURL == repositoryURL else { return }
            isLoading = false
            switch result {
            case .success:
                isCreatingNew = false
                newBranchName = ""
                isPresented.wrappedValue = false
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
