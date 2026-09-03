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
///
/// 状态变化通过观察者体系通知（`addObserver` / `ProjectProvidingObserverHandle`），
/// 与 Lumi 其他 Provider（如 `ThemeProviding`）保持一致，不依赖 Combine。
@MainActor
public final class ProjectManager: ProjectProviding, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.lumi.plugin.projects", category: "Projects")
    nonisolated public static let emoji = "📁"
    nonisolated static let verbose = false

    public private(set) var projects: [Project] = []
    public private(set) var currentProject: Project?

    /// 项目列表 JSON 文件的 URL。
    public private(set) var storeURL: URL

    /// 观察者集合（弱引用，自动清理失联者）。
    private var observers: [WeakObserver] = []

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
        var openedID: UUID?
        if let index = projects.firstIndex(where: { $0.url.standardizedFileURL == standardized }) {
            // 已存在项目：仅更新最近打开时间并设为当前项目，不重排列表
            // （对齐旧版：点击项目只切换当前项目，列表顺序保持固定）。
            var project = projects[index]
            project.lastOpenedAt = Date()
            projects[index] = project
            openedID = project.id
        } else {
            // 新项目：插入非置顶区最前（对齐旧版新建项目 order=-1 显示在最前）。
            let project = Project(url: standardized, lastOpenedAt: Date())
            insertToFront(project)
            openedID = project.id
        }
        currentProject = projects.first(where: { $0.url.standardizedFileURL == standardized })
        persist()
        notify(.projectsChanged)
        notify(.selectionChanged(projectID: openedID))
    }

    public func closeCurrentProject() {
        guard currentProject != nil else { return }
        currentProject = nil
        if Self.verbose {
            Self.logger.debug("\(self.t)closed current project")
        }
        persist()
        notify(.selectionChanged(projectID: nil))
    }

    public func addProject(at url: URL) {
        let standardized = url.standardizedFileURL
        guard !projects.contains(where: { $0.url.standardizedFileURL == standardized }) else {
            if Self.verbose {
                Self.logger.debug("\(self.t)project already exists: \(standardized.path, privacy: .public)")
            }
            return
        }
        // 新项目插入非置顶区最前（对齐旧版新建项目 order=-1 排最前）。
        insertToFront(Project(url: standardized))
        resortPinned()
        persist()
        notify(.projectsChanged)
    }

    public func removeProject(id: UUID) {
        let oldCount = projects.count
        projects.removeAll { $0.id == id }
        guard projects.count != oldCount else { return }
        let removedCurrent = currentProject?.id == id
        if removedCurrent {
            currentProject = nil
        }
        persist()
        notify(.projectsChanged)
        if removedCurrent {
            notify(.selectionChanged(projectID: nil))
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
        notify(.projectsChanged)
    }

    public func setCurrentProject(id: UUID?) {
        guard currentProject?.id != id else { return }
        if let id {
            currentProject = projects.first(where: { $0.id == id })
        } else {
            currentProject = nil
        }
        persist()
        notify(.selectionChanged(projectID: id))
    }

    public func refresh() {
        loadFromDisk()
    }

    public func notifyDataChanged() {
        notify(.dataChanged)
    }

    public func persist() {
        writeToDisk()
    }

    // MARK: - Observation

    @discardableResult
    public func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle {
        let observer = Observer(owner: self, callback: callback)
        observers.append(WeakObserver(observer))
        return observer
    }

    private func remove(_ observer: Observer) {
        observers.removeAll { $0.observer === observer }
    }

    private func notify(_ event: ProjectProvidingEvent) {
        observers.removeAll { $0.observer == nil }
        for observer in observers {
            observer.observer?.invoke(event)
        }
    }

    // MARK: - Persistence

    /// 磁盘存储容器：项目列表 + 上次会话的当前项目。
    ///
    /// `currentProjectID` 记录上次打开/选中的项目，下次启动时恢复为
    /// `currentProject`（若该 id 在列表中仍存在）。
    private struct ProjectStore: Codable {
        var projects: [Project]
        var currentProjectID: UUID?
    }

    /// 重新从磁盘加载项目列表，并恢复上次会话的当前项目。
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storeURL) else {
            if Self.verbose {
                Self.logger.debug("\(self.t)no store at \(self.storeURL.path, privacy: .public), start empty")
            }
            projects = []
            currentProject = nil
            notify(.projectsChanged)
            return
        }
        do {
            // 优先按容器格式解码（含 currentProjectID）。
            if let store = try? JSONDecoder().decode(ProjectStore.self, from: data) {
                projects = store.projects
                resortPinned()
                if let id = store.currentProjectID {
                    currentProject = projects.first { $0.id == id }
                } else {
                    currentProject = nil
                }
            } else {
                // 兼容旧版纯数组格式（无 currentProject 记录）。
                let decoded = try JSONDecoder().decode([Project].self, from: data)
                projects = decoded
                resortPinned()
                currentProject = nil
            }
            if Self.verbose {
                Self.logger.info("\(self.t)loaded \(self.projects.count) projects from \(self.storeURL.path, privacy: .public)")
            }
            notify(.projectsChanged)
        } catch {
            Self.logger.error("\(self.t)failed to decode projects: \(error.localizedDescription, privacy: .public)")
            projects = []
            currentProject = nil
            notify(.projectsChanged)
        }
    }

    /// 写入项目列表到磁盘（原子写入，失败仅记录日志）。
    private func writeToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let store = ProjectStore(projects: projects, currentProjectID: currentProject?.id)
            let data = try encoder.encode(store)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            Self.logger.error("\(self.t)failed to persist projects: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Ordering

    /// 把新项目插入「非置顶区」最前（旧版新建项目 order=-1 的语义）：
    /// 保持所有置顶项目在前，把新项目插入到置顶区之后、其余项目之前。
    /// 仅用于新增项目；点击/打开已有项目不重排。
    private func insertToFront(_ project: Project) {
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

    // MARK: - Observer Types

    private final class Observer: ProjectProvidingObserverHandle {
        private weak var owner: ProjectManager?
        private let callback: (ProjectProvidingEvent) -> Void
        private var cancelled = false

        init(owner: ProjectManager, callback: @escaping (ProjectProvidingEvent) -> Void) {
            self.owner = owner
            self.callback = callback
        }

        func cancel() {
            guard !cancelled else { return }
            cancelled = true
            owner?.remove(self)
        }

        func invoke(_ event: ProjectProvidingEvent) {
            guard !cancelled else { return }
            callback(event)
        }
    }

    private final class WeakObserver {
        weak var observer: Observer?

        init(_ observer: Observer) {
            self.observer = observer
        }
    }
}
