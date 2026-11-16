import Foundation
import ProviderProjects

/// 项目所在卷状态模型：缓存每个项目的卷类型，供侧边栏标识使用。
///
/// 设计要点：
/// - **按需刷新**：只在项目首次加载、应用回到前台、卷挂载状态变化时读取，
///   渲染过程不触碰文件系统。
/// - **结果缓存**：以项目 id 为键缓存卷类型；项目路径变化时自动重新判定。
/// - **异步读取**：卷属性查询可能因网络卷而阻塞，放到后台执行后回到主线程更新。
/// - **并发受限**：项目很多时串行查询会明显拖慢徽标出现，因此按固定并发度
///   分批读取（与 `ProjectActivityModel` 的策略一致）。
@MainActor
final class ProjectVolumeModel: ObservableObject {
    /// 各项目的卷类型。
    @Published private(set) var statuses: [UUID: ProjectVolumeStatus] = [:]

    private let resolver: any ProjectVolumeResolving

    /// 缓存对应的项目路径；路径变化时使缓存失效。
    private var cachedURLs: [UUID: URL] = [:]

    /// 单批并发查询数。
    private let maxConcurrentLoads: Int

    private var refreshTask: Task<Void, Never>?

    init(
        resolver: any ProjectVolumeResolving = FileSystemProjectVolumeResolver(),
        maxConcurrentLoads: Int = 4
    ) {
        self.resolver = resolver
        self.maxConcurrentLoads = max(1, maxConcurrentLoads)
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Refresh

    /// 为给定项目列表刷新卷类型。
    ///
    /// - Parameters:
    ///   - projects: 当前项目列表。
    ///   - force: 为 true 时忽略缓存重新判定（应用回前台、卷挂载变化）。
    func refresh(for projects: [Project], force: Bool = false) {
        refreshTask?.cancel()
        refreshTask = nil

        // 清理已移除项目的缓存，避免字典无限增长。
        let validIDs = Set(projects.map(\.id))
        statuses = statuses.filter { validIDs.contains($0.key) }
        cachedURLs = cachedURLs.filter { validIDs.contains($0.key) }

        let pending = projects.filter { project in
            force
                || statuses[project.id] == nil
                || cachedURLs[project.id] != project.url
        }
        guard !pending.isEmpty else { return }

        // 先占位缓存，避免项目变更事件连续触发时重复查询。
        for project in pending {
            cachedURLs[project.id] = project.url
        }

        refreshTask = Task { [weak self] in
            await self?.load(pending: pending)
        }
    }

    /// 取消进行中的读取（视图消失时调用）。
    func cancel() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Badge

    /// 侧边栏标识；尚未判定完成或本机卷时返回 `.none`。
    func badge(for projectID: UUID) -> ProjectVolumeBadge {
        switch statuses[projectID] {
        case .externalVolume:
            return .external
        case .unavailable:
            return .unavailable
        default:
            return .none
        }
    }

    // MARK: - Loading

    /// 分批并发查询卷属性。
    ///
    /// 每批最多 `maxConcurrentLoads` 个项目，批内并发执行（网络卷的查询可以
    /// 彼此重叠，不必排队等待），批与批之间让出主线程。
    private func load(pending: [Project]) async {
        var settled: [UUID: ProjectVolumeStatus] = [:]
        var batch: [Project] = []
        for project in pending {
            guard !Task.isCancelled else { return }
            batch.append(project)
            if batch.count >= maxConcurrentLoads {
                await loadBatch(batch, into: &settled)
                batch.removeAll(keepingCapacity: true)
            }
        }
        if !batch.isEmpty {
            await loadBatch(batch, into: &settled)
        }

        // 被取消的轮次结果已经过期，不能再覆盖缓存。
        guard !Task.isCancelled else { return }
        statuses.merge(settled) { _, latest in latest }
    }

    private func loadBatch(
        _ batch: [Project],
        into settled: inout [UUID: ProjectVolumeStatus]
    ) async {
        let resolver = self.resolver
        await withTaskGroup(of: (UUID, ProjectVolumeStatus).self) { group in
            for project in batch {
                group.addTask {
                    let status = await resolver.status(forProjectURL: project.url)
                    return (project.id, status)
                }
            }
            for await (id, status) in group {
                guard !Task.isCancelled else { return }
                settled[id] = status
            }
        }
    }
}
