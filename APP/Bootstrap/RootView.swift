import GitOKUI
import MagicAlert
import MagicKit
import OSLog
import GitOKCoreKit
import SwiftData
import SwiftUI

/// 根视图容器组件
/// 为应用提供统一的上下文环境，包括数据提供者和插件提供者
struct RootView<Content>: View, SuperEvent, SuperLog where Content: View {
    /// 日志标识符
    static var emoji: String { "🚉" }

    /// 是否启用详细日志输出
    static var verbose: Bool { false }

    /// 视图内容
    var content: Content

    /// 应用提供者
    var appProvider: AppVM

    /// 插件提供者
    var pluginProvider: PluginVM

    /// 主题提供者
    @ObservedObject var themeProvider: AppThemeVM

    /// Git 数据提供者
    var git: DataVM

    /// 当前项目状态
    var projectVM: ProjectVM

    /// 拖拽覆盖层是否可见
    @State private var isDropTargeted = false

    /// 仓库管理器
    private let repoManager: RepoManager

    init(@ViewBuilder content: () -> Content) {
        let start = Date()
        os_log("\(Self.t)🚀 Startup begin: RootView.init")

        let contentStart = Date()
        self.content = content()
        os_log("\(Self.t)✅ Startup step: RootView content built elapsed=\(String(format: "%.3f", Date().timeIntervalSince(contentStart)))s")

        let containerStart = Date()
        let c = AppConfig.getContainer()
        os_log("\(Self.t)✅ Startup step: RootView container ready elapsed=\(String(format: "%.3f", Date().timeIntervalSince(containerStart)))s")

        let repoStart = Date()
        self.repoManager = RepoManager(modelContext: ModelContext(c))
        os_log("\(Self.t)✅ Startup step: RepoManager ready elapsed=\(String(format: "%.3f", Date().timeIntervalSince(repoStart)))s")

        // 初始化提供者
        let providersStart = Date()
        self.appProvider = AppVM(repoManager: self.repoManager)
        self.pluginProvider = PluginVM()
        self.themeProvider = AppThemeVM(pluginProvider: self.pluginProvider)
        os_log("\(Self.t)✅ Startup step: providers ready elapsed=\(String(format: "%.3f", Date().timeIntervalSince(providersStart)))s")

        // 初始化数据提供者
        var initialProject: Project?
        do {
            let projectsStart = Date()
            os_log("\(Self.t)🚀 Startup begin: load projects")
            let projects = try self.repoManager.projectRepo.findAll(sortedBy: .ascending)
            os_log("\(Self.t)✅ Startup end: load projects count=\(projects.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(projectsStart)))s")

            let dataStart = Date()
            self.git = DataVM(projects: projects, repoManager: self.repoManager)
            os_log("\(Self.t)✅ Startup step: DataVM ready elapsed=\(String(format: "%.3f", Date().timeIntervalSince(dataStart)))s")

            // 恢复上次选中的项目
            let restoreStart = Date()
            let savedPath = self.repoManager.stateRepo.projectPath
            initialProject = projects.first(where: { $0.path == savedPath })
            if initialProject == nil, let firstProject = projects.first {
                initialProject = firstProject
                self.repoManager.stateRepo.setProjectPath(firstProject.path)
            }
            os_log("\(Self.t)✅ Startup step: restore project savedPath=\(savedPath) selected=\(initialProject?.path ?? "nil") elapsed=\(String(format: "%.3f", Date().timeIntervalSince(restoreStart)))s")

            let projectVMStart = Date()
            self.projectVM = ProjectVM(project: initialProject, repoManager: self.repoManager)
            os_log("\(Self.t)✅ Startup step: ProjectVM ready elapsed=\(String(format: "%.3f", Date().timeIntervalSince(projectVMStart)))s")
        } catch let e {
            os_log(.error, "\(Self.t) Failed to load projects: \(e.localizedDescription)")
            self.git = DataVM(projects: [], repoManager: self.repoManager)
            self.projectVM = ProjectVM(project: initialProject, repoManager: self.repoManager)
        }

        os_log("\(Self.t)✅ Startup end: RootView.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                themeProvider.activeChromeTheme
                    .makeGlobalBackground(proxy: proxy)
                    .ignoresSafeArea()
            }

            hostedContent
            .environmentObject(appProvider)
            .environmentObject(pluginProvider)
            .environmentObject(themeProvider)
            .environmentObject(git)
            .environmentObject(projectVM)

            // 拖拽覆盖层
            if isDropTargeted {
                DropOverlayCard(
                    title: "松开即可添加项目",
                    subtitle: "将文件夹拖到此处，自动切换为当前项目"
                )
                .transition(.opacity)
            }
        }
        .tint(themeProvider.accentColor)
        .preferredColorScheme(themeProvider.preferredColorScheme)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onAppear {
            // 注册打开项目的回调（单例桥梁模式，确保时序可靠）
            OpenProjectHandler.shared.onOpenProject = { [self] path in
                self.handleOpenProject(path: path)
            }
        }
    }

    @ViewBuilder
    private var hostedContent: some View {
        if pluginProvider.hasPlugins {
            pluginProvider.getRootViewWrapper(context: pluginRootContext) {
                baseContent
            }
        } else {
            baseContent
        }
    }

    private var baseContent: some View {
        content
            .withMagicToast()
            .navigationTitle("")
    }

    private var pluginRootContext: GitOKPluginContext {
        GitOKPluginContext(
            projectURL: projectVM.project?.url,
            onCleanStatusUpdate: { isClean in
                projectVM.updateIsClean(isClean)
            },
            onGitDirectoryChange: { change in
                postGitDirectoryChange(change)
            },
            onUnpushedCommitsUpdate: { count, hashes in
                projectVM.updateUnpushedCommits(count, hashes: hashes)
            },
            onRemoteTrackingUpdate: { status, fetchedAt in
                projectVM.updateRemoteTracking(status, fetchedAt: fetchedAt)
            }
        )
    }

    // MARK: - Drop Handler

    /// 处理拖拽释放事件
    /// - Parameter providers: 拖拽的文件提供者列表
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier("public.folder") ||
                  provider.hasItemConformingToTypeIdentifier("public.directory") ||
                  provider.hasItemConformingToTypeIdentifier("public.file-url") else {
                continue
            }

            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    // 尝试作为 URL 对象处理
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self.handleOpenProject(path: url.path)
                        }
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.handleOpenProject(path: url.path)
                }
            }

            // 只处理第一个有效的提供者
            return
        }
    }

    // MARK: - Open Project Handler

    /// 处理打开项目请求
    /// - 如果项目已存在于列表中，直接选中它
    /// - 如果项目不存在，添加到列表并选中
    /// - Parameter path: 项目路径
    private func handleOpenProject(path: String) {
        guard !path.isEmpty else { return }

        // 检查路径是否存在
        guard FileManager.default.fileExists(atPath: path) else {
            os_log(.error, "\(Self.t) Open project path does not exist: \(path)")
            return
        }

        // 在已有项目中查找
        if let existingProject = git.projects.first(where: { $0.path == path }) {
            os_log("\(Self.t)📂 Selecting existing project: \(path)")
            withAnimation {
                // 如果项目已在列表中，将其移到第一位并选中
                if let index = git.projects.firstIndex(where: { $0.id == existingProject.id }) {
                    git.projects.remove(at: index)
                }
                git.projects.insert(existingProject, at: 0)
                projectVM.setProject(existingProject, reason: "OpenProject")
            }
        } else {
            os_log("\(Self.t)📂 Adding new project: \(path)")
            // 添加新项目并选中
            let url = URL(fileURLWithPath: path, isDirectory: true)
            withAnimation {
                if let addedProject = git.addProject(url: url, using: git.repoManager.projectRepo) {
                    projectVM.setProject(addedProject, reason: "OpenProject")
                }
            }
        }

        // 显示侧边栏以确保项目列表可见
        appProvider.showSidebar(reason: "OpenProject")
    }

    private func postGitDirectoryChange(_ change: GitOKGitDirectoryChange) {
        guard let project = projectVM.project else { return }
        guard project.url.standardizedFileURL == change.projectURL.standardizedFileURL else { return }

        var additionalInfo: [String: Any] = [
            "gitPath": change.gitDirectoryPath,
            "changeKind": change.changeKind,
            "headChanged": change.headChanged,
            "indexChanged": change.indexChanged,
            "stashChanged": change.stashChanged,
            "refsChanged": change.refsChanged
        ]

        if let previousHead = change.previousHead {
            additionalInfo["previousHead"] = previousHead
        }

        if let head = change.head {
            additionalInfo["head"] = head
        }

        project.postEvent(
            name: .projectGitDirectoryDidChange,
            operation: "gitDirectoryChanged",
            additionalInfo: additionalInfo
        )

        if change.headChanged {
            project.postEvent(name: .projectGitHeadDidChange, operation: "gitHeadChanged", additionalInfo: additionalInfo)
        }

        if change.indexChanged {
            project.postEvent(name: .projectGitIndexDidChange, operation: "gitIndexChanged", additionalInfo: additionalInfo)
        }

        if change.stashChanged {
            project.postEvent(name: .projectGitStashDidChange, operation: "gitStashChanged", additionalInfo: additionalInfo)
        }

        if change.refsChanged {
            project.postEvent(name: .projectGitRefsDidChange, operation: "gitRefsChanged", additionalInfo: additionalInfo)
        }
    }
}

extension View {
    /// 将当前视图包裹在RootView中
    /// - Returns: 被RootView包裹的视图
    func inRootView() -> some View {
        RootView {
            self
        }
    }
}

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
