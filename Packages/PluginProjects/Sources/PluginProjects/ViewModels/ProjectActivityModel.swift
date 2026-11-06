import Foundation
import ProviderProjects

/// 项目活跃度模型：后台读取各仓库的最近提交时间，供「最近更新」排序使用。
///
/// 设计要点：
/// - **按需加载**：只有当用户切到「最近更新」展示方式时才读取提交时间，
///   避免在默认的手动排序下为每个项目启动 git 进程。
/// - **结果缓存**：以项目 id 为键缓存最近提交时间，切换展示方式来回时
///   不重复读取；项目被移除时缓存同步清理。
/// - **并发受限**：项目很多时同时启动几十个 git 进程会拖慢机器，因此按
///   固定并发度分批读取。
@MainActor
final class ProjectActivityModel: ObservableObject {
    /// 各项目的最近提交时间。
    @Published private(set) var commitDates: [UUID: Date] = [:]

    /// 正在读取中的项目 id（用于行内的加载指示）。
    @Published private(set) var loadingProjectIDs: Set<UUID> = []

    /// 读取仓库提交时间的底层能力；为 nil 时（例如 Git Provider 未注册）
    /// 全部项目回退到「最近打开时间」排序。
    private let capability: (any ProjectActivityCapability)?

    /// 单批并发读取数。
    private let maxConcurrentLoads: Int

    /// 正在进行的读取任务；切换展示方式或项目列表变化时取消旧任务。
    private var loadTask: Task<Void, Never>?

    init(capability: (any ProjectActivityCapability)?, maxConcurrentLoads: Int = 4) {
        self.capability = capability
        self.maxConcurrentLoads = max(1, maxConcurrentLoads)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Refresh

    /// 为给定项目列表刷新最近提交时间。
    ///
    /// - Parameters:
    ///   - projects: 需要读取的项目列表。
    ///   - force: 为 true 时忽略缓存重新读取。
    func refresh(for projects: [Project], force: Bool = false) {
        loadTask?.cancel()
        loadTask = nil

        // 清理已移除项目的缓存，避免字典无限增长。
        let validIDs = Set(projects.map(\.id))
        commitDates = commitDates.filter { validIDs.contains($0.key) }

        guard let capability else {
            loadingProjectIDs.removeAll()
            return
        }

        let pending = projects.filter { force || commitDates[$0.id] == nil }
        guard !pending.isEmpty else {
            loadingProjectIDs.removeAll()
            return
        }

        // 用新任务的在途集合覆盖旧值：上一轮任务已被取消，它留下的
        // loading 标记若残留会让加载指示器一直转。
        loadingProjectIDs = Set(pending.map(\.id))

        loadTask = Task { [weak self] in
            await self?.load(pending: pending, capability: capability)
        }
    }

    /// 取消进行中的读取（视图消失时调用）。
    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        loadingProjectIDs.removeAll()
    }

    // MARK: - Loading

    private func load(
        pending: [Project],
        capability: any ProjectActivityCapability
    ) async {
        // 分批读取：每批最多 maxConcurrentLoads 个项目，批与批之间让出
        // 主线程，避免大批量项目时长时间占用 UI。
        var batch: [Project] = []
        for project in pending {
            guard !Task.isCancelled else { return }
            batch.append(project)
            if batch.count >= maxConcurrentLoads {
                await loadBatch(batch, capability: capability)
                batch.removeAll(keepingCapacity: true)
            }
        }
        if !batch.isEmpty {
            await loadBatch(batch, capability: capability)
        }
    }

    private func loadBatch(
        _ batch: [Project],
        capability: any ProjectActivityCapability
    ) async {
        await withTaskGroup(of: (UUID, Date?).self) { group in
            for project in batch {
                group.addTask { [capability] in
                    let date = await capability.lastCommitDate(inRepository: project.url)
                    return (project.id, date)
                }
            }
            for await (id, date) in group {
                guard !Task.isCancelled else { return }
                apply(date: date, for: id)
            }
        }
    }

    private func apply(date: Date?, for id: UUID) {
        loadingProjectIDs.remove(id)
        guard let date else {
            // 读取失败或仓库没有提交：不写入缓存，下次刷新会重试。
            return
        }
        commitDates[id] = date
    }
}
