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
            var project = projects[index]
            project.lastOpenedAt = Date()
            projects.remove(at: index)
            moveToRecentFront(project)
            openedID = project.id
        } else {
            let project = Project(url: standardized)
            moveToRecentFront(project)
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
        projects.append(Project(url: standardized))
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
        notify(.selectionChanged(projectID: id))
    }

    public func refresh() {
        loadFromDisk()
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

    /// 重新从磁盘加载项目列表。
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
            let decoded = try JSONDecoder().decode([Project].self, from: data)
            projects = decoded
            resortPinned()
            // currentProject 不持久化，启动后保持未打开状态。
            currentProject = nil
            if Self.verbose {
                Self.logger.info("\(self.t)loaded \(decoded.count) projects from \(self.storeURL.path, privacy: .public)")
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
