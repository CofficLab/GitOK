import MagicAlert
import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 根视图容器组件
/// 为应用提供统一的上下文环境，包括数据提供者、图标提供者和插件提供者
struct RootView<Content>: View, SuperEvent, SuperLog where Content: View {
    /// 日志标识符
    static var emoji: String { "🚉" }

    /// 是否启用详细日志输出
    static var verbose: Bool { false }

    /// 视图内容
    var content: Content

    /// 应用提供者
    var appProvider: AppVM

    /// 图标提供者
    var iconProvider: IconProvider

    /// 插件提供者
    var pluginProvider: PluginVM

    /// Git 数据提供者
    var git: DataVM

    /// 当前项目状态
    var projectVM: ProjectVM

    /// 仓库管理器
    private let repoManager: RepoManager

    init(@ViewBuilder content: () -> Content) {
        self.content = content()

        let c = AppConfig.getContainer()
        self.repoManager = RepoManager(modelContext: ModelContext(c))

        // 初始化提供者
        self.appProvider = AppVM(repoManager: self.repoManager)
        self.iconProvider = IconProvider()
        self.pluginProvider = PluginVM()

        // 初始化数据提供者
        var initialProject: Project?
        do {
            let projects = try self.repoManager.projectRepo.findAll(sortedBy: .ascending)
            self.git = DataVM(projects: projects, repoManager: self.repoManager)

            // 恢复上次选中的项目
            let savedPath = self.repoManager.stateRepo.projectPath
            initialProject = projects.first(where: { $0.path == savedPath })
            if initialProject == nil, let firstProject = projects.first {
                initialProject = firstProject
                self.repoManager.stateRepo.setProjectPath(firstProject.path)
            }

            self.projectVM = ProjectVM(project: initialProject, repoManager: self.repoManager)
        } catch let e {
            os_log(.error, "\(Self.t) Failed to load projects: \(e.localizedDescription)")
            self.git = DataVM(projects: [], repoManager: self.repoManager)
            self.projectVM = ProjectVM(project: initialProject, repoManager: self.repoManager)
        }
    }

    var body: some View {
        content
            .withMagicToast()
            .environmentObject(appProvider)
            .environmentObject(iconProvider)
            .environmentObject(pluginProvider)
            .environmentObject(git)
            .environmentObject(projectVM)
            .navigationTitle("")
            .onAppOpenProject { path in
                handleOpenProject(path: path)
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
                git.addProject(url: url, using: git.repoManager.projectRepo)
                // addProject 会将新项目插入到第一位，直接选中它
                if let newProject = git.projects.first {
                    projectVM.setProject(newProject, reason: "OpenProject")
                }
            }
        }

        // 显示侧边栏以确保项目列表可见
        appProvider.showSidebar(reason: "OpenProject")
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
