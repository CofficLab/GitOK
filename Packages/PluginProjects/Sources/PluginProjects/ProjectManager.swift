import Foundation
import KitSuperLog
import os
import ProviderProjects

/// `ProjectProviding` 的默认实现。
///
/// 管理 GitOK 项目列表（侧边栏数据源），并把项目列表持久化到
/// 插件数据目录下的 `projects.json`（目录遵循 Lumi 存储规律：
/// `~/Library/Application Support/<bundleID>/db_<env>_v<major>/Projects/`）。
///
/// 排序规则（与旧版一致）：
/// - 置顶（pinned）项目在最上方；
/// - 其余按最近打开时间降序（未打开过的排最后）。
@MainActor
public final class ProjectManager: ProjectProviding, ObservableObject, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.lumi.plugin.projects", category: "Projects")
    nonisolated public static let emoji = "📁"
    nonisolated static let verbose = false

    @Published public private(set) var projects: [Project] = []
    @Published public private(set) var currentProject: Project?

    /// 项目列表 JSON 文件的 URL。
    public private(set) var storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
        if Self.verbose {
            Self.logger.info("\(self.t)ProjectManager initialized, store: \(storeURL.path, privacy: .public)")
        }
        loadFromDisk()
    }

    // MARK: - ProjectProviding

    /// 切换持久化目录（通常在插件 onBoot 阶段由真实存储目录替换占位目录），
    /// 并重新从磁盘加载。
    public func setStoreURL(_ url: URL) {
        guard storeURL != url else { return }
        storeURL = url
        loadFromDisk()
    }

    public func openProject(at url: URL) {
        let standardized = url.standardizedFileURL
        if let index = projects.firstIndex(where: { $0.url.standardizedFileURL == standardized }) {
            var project = projects[index]
            project.lastOpenedAt = Date()
            projects.remove(at: index)
            moveToRecentFront(project)
        } else {
            moveToRecentFront(Project(url: standardized))
        }
        currentProject = projects.first(where: { $0.url.standardizedFileURL == standardized })
        persist()
    }

    public func closeCurrentProject() {
        guard currentProject != nil else { return }
        currentProject = nil
        if Self.verbose {
            Self.logger.debug("\(self.t)closed current project")
        }
    }

    public func addProject(at url: URL) {
        let standardized = url.standardizedFileURL
        guard !projects.contains(where: { $0.url.standardizedFileURL == standardized }) else {
            if Self.verbose {
                Self.logger.debug("\(self.t)project already exists: \(standardized.path, privacy: .public)")
            }
            return
        }
        projects.append(Project(url: standardized))
        resortPinned()
        persist()
    }

    public func removeProject(id: UUID) {
        let oldCount = projects.count
        projects.removeAll { $0.id == id }
        if projects.count != oldCount {
            if currentProject?.id == id {
                currentProject = nil
            }
            persist()
        }
    }

    public func pinProject(id: UUID, isPinned: Bool) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        var project = projects[index]
        guard project.isPinned != isPinned else { return }
        project.isPinned = isPinned
        projects[index] = project
        resortPinned()
        persist()
    }

    public func setCurrentProject(id: UUID?) {
        guard currentProject?.id != id else { return }
        if let id {
            currentProject = projects.first(where: { $0.id == id })
        } else {
            currentProject = nil
        }
    }

    public func refresh() {
        loadFromDisk()
    }

    public func persist() {
        writeToDisk()
    }

    // MARK: - Persistence

    /// 重新从磁盘加载项目列表。
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storeURL) else {
            if Self.verbose {
                Self.logger.debug("\(self.t)no store at \(self.storeURL.path, privacy: .public), start empty")
            }
            projects = []
            currentProject = nil
            return
        }
        do {
            let decoded = try JSONDecoder().decode([Project].self, from: data)
            projects = decoded
            resortPinned()
            // currentProject 不持久化，启动后保持未打开状态。
            currentProject = nil
            if Self.verbose {
                Self.logger.info("\(self.t)loaded \(decoded.count) projects from \(self.storeURL.path, privacy: .public)")
            }
        } catch {
            Self.logger.error("\(self.t)failed to decode projects: \(error.localizedDescription, privacy: .public)")
            projects = []
            currentProject = nil
        }
    }

    /// 写入项目列表到磁盘（原子写入，失败仅记录日志）。
    private func writeToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(projects)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            Self.logger.error("\(self.t)failed to persist projects: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Ordering

    /// 把项目移到「非置顶区」最前（recent 语义，不依赖时间戳比较）：
    /// 保持所有置顶项目在前，把指定项目插入到置顶区之后、其余最近打开项目之前。
    private func moveToRecentFront(_ project: Project) {
        var list = projects.filter { $0.id != project.id }
        let pinnedCount = list.filter { $0.isPinned }.count
        list.insert(project, at: pinnedCount)
        projects = list
    }

    /// 置顶项目统一前置（pinned 内部保持原有相对顺序）。
    private func resortPinned() {
        let pinned = projects.filter { $0.isPinned }
        let unpinned = projects.filter { !$0.isPinned }
        projects = pinned + unpinned
    }
}
